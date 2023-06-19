/*
 *  Copyright (c) 2000-2022 Inria
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright notice,
 *  this list of conditions and the following disclaimer in the documentation
 *  and/or other materials provided with the distribution.
 *  * Neither the name of the ALICE Project-Team nor the names of its
 *  contributors may be used to endorse or promote products derived from this
 *  software without specific prior written permission.
 * 
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 *
 *  Contact: Bruno Levy
 *
 *     https://www.inria.fr/fr/bruno-levy
 *
 *     Inria,
 *     Domaine de Voluceau,
 *     78150 Le Chesnay - Rocquencourt
 *     FRANCE
 *
 */

#include "nl_superlu.h"
#include "nl_context.h"

#include <slu_cdefs.h>
#include <slu_ddefs.h>
#include <slu_util.h>
#include <supermatrix.h>



typedef superlu_options_t* superlu_options_ptr;


NLboolean nlExtensionIsInitialized_SUPERLU() {
	return NL_TRUE;
}

static void nlTerminateExtension_SUPERLU(void) {
}

NLboolean nlInitExtension_SUPERLU(void) {
    return NL_TRUE;
}

/************************************************************************/

/**
 * \brief The class for matrices factorized with SuperLU.
 */
typedef struct {
    /**
     * \brief number of rows 
     */    
    NLuint m;

    /**
     * \brief number of columns 
     */    
    NLuint n;

    /**
     * \brief Matrix type
     * \details set to NL_MATRIX_OTHER
     */
    NLenum type;

    /**
     * \brief Destructor
     */
    NLDestroyMatrixFunc destroy_func;

    /**
     * \brief Matrix x vector product
     */
    NLMultMatrixVectorFunc mult_func;

    /**
     * \brief Lower triangular factor.
     */
    SuperMatrix L;

    /**
     * \brief Upper triangular factor.
     */
    SuperMatrix U;

    /**
     * \brief Rows permutation.
     */
    int* perm_r;

    /**
     * \brief Columns permutation.
     */
    int* perm_c;

    /**
     * \brief Indicates whether the matrix or its transpose
     *  was factorized.
     */
    trans_t trans;
    
} NLSuperLUFactorizedMatrix;


static void nlSuperLUFactorizedMatrixDestroy(NLSuperLUFactorizedMatrix* M) {
    if(nlExtensionIsInitialized_SUPERLU()) {
	Destroy_SuperNode_Matrix(&M->L);
	Destroy_CompCol_Matrix(&M->U);
    }
    NL_DELETE_ARRAY(M->perm_r);
    NL_DELETE_ARRAY(M->perm_c);
}

static void nlSuperLUFactorizedMatrixMult(
    NLSuperLUFactorizedMatrix* M, const double* x, double* y
) {
    SuperMatrix B;
    SuperLUStat_t stat;
    int info = 0;
    NLuint i;

    /* Create vector */
    dCreate_Dense_Matrix(
        &B, (int)(M->n), 1, y, (int)(M->n), 
        SLU_DN, /* Fortran-type column-wise storage */
        SLU_D,  /* doubles */
        SLU_GE  /* general */
    );

    /* copy rhs onto y (superLU matrix-vector product expects it here */
    for(i = 0; i < M->n; i++){
        y[i] = x[i];
    }

    /* Call SuperLU triangular solve */
    StatInit(&stat) ;

    dgstrs(
       M->trans, &M->L, &M->U, M->perm_c, M->perm_r, &B, &stat, &info
    );

    StatFree(&stat) ;
    
    /*  Only the "store" structure needs to be 
     *  deallocated (the array has been allocated
     * by client code).
     */
    Destroy_SuperMatrix_Store(&B) ;
}

/*
 * Copied from SUPERLU/dgssv.c, removed call to linear solve.
 */
static void dgssv_factorize_only(
      superlu_options_t *options, SuperMatrix *A, int *perm_c, int *perm_r,
      SuperMatrix *L, SuperMatrix *U,
      SuperLUStat_t *stat, int *info, trans_t *trans
) {
    SuperMatrix *AA = NULL;
        /* A in SLU_NC format used by the factorization routine.*/
    SuperMatrix AC; /* Matrix postmultiplied by Pc */
    int      lwork = 0, *etree, i;
    GlobalLU_t Glu; /* Not needed on return. */
    
    /* Set default values for some parameters */
    int      panel_size;     /* panel size */
    int      relax;          /* no of columns in a relaxed snodes */
    int      permc_spec;

    nl_assert(A->Stype == SLU_NR || A->Stype == SLU_NC);
    
    *trans = NOTRANS;

    if ( options->Fact != DOFACT ) *info = -1;
    else if ( A->nrow != A->ncol || A->nrow < 0 ||
	 (A->Stype != SLU_NC && A->Stype != SLU_NR) ||
	 A->Dtype != SLU_D || A->Mtype != SLU_GE )
	*info = -2;
    if ( *info != 0 ) {
	i = -(*info);
	input_error("SUPERLU/OpenNL dgssv_factorize_only", &i);
	return;
    }

    /* Convert A to SLU_NC format when necessary. */
    if ( A->Stype == SLU_NR ) {
	NRformat *Astore = (NRformat*)A->Store;
	AA = NL_NEW(SuperMatrix);
	dCreate_CompCol_Matrix(
	    AA, A->ncol, A->nrow, Astore->nnz, 
	    (double*)Astore->nzval, Astore->colind, Astore->rowptr,
	    SLU_NC, A->Dtype, A->Mtype
	);
	*trans = TRANS;
    } else {
        if ( A->Stype == SLU_NC ) AA = A;
    }

    nl_assert(AA != NULL);
    
    /*
     * Get column permutation vector perm_c[], according to permc_spec:
     *   permc_spec = NATURAL:  natural ordering 
     *   permc_spec = MMD_AT_PLUS_A: minimum degree on structure of A'+A
     *   permc_spec = MMD_ATA:  minimum degree on structure of A'*A
     *   permc_spec = COLAMD:   approximate minimum degree column ordering
     *   permc_spec = MY_PERMC: the ordering already supplied in perm_c[]
     */
    permc_spec = (int)(options->ColPerm);
    if ( permc_spec != MY_PERMC && options->Fact == DOFACT )
	get_perm_c(permc_spec, AA, perm_c);
    
    etree = NL_NEW_ARRAY(int,A->ncol);
    sp_preorder(options, AA, perm_c, etree, &AC);
    panel_size = sp_ienv(1);
    relax = sp_ienv(2);
    dgstrf(options, &AC, relax, panel_size, etree,
            NULL, lwork, perm_c, perm_r, L, U, &Glu, stat, info);

    NL_DELETE_ARRAY(etree);
    Destroy_CompCol_Permuted(&AC);
    if ( A->Stype == SLU_NR ) {
	Destroy_SuperMatrix_Store(AA);
	NL_DELETE(AA);
    }
}


NLMatrix nlMatrixFactorize_SUPERLU(
    NLMatrix M, NLenum solver
) {
    NLSuperLUFactorizedMatrix* LU = NULL;
    NLCRSMatrix* CRS = NULL;
    SuperMatrix superM;
    NLuint n = M->n;
    superlu_options_t options;
    SuperLUStat_t     stat;
    NLint info = 0;       /* status code  */
    
    nl_assert(M->m == M->n);

    if(M->type == NL_MATRIX_CRS) {
        CRS = (NLCRSMatrix*)M;
    } else if(M->type == NL_MATRIX_SPARSE_DYNAMIC) {
        CRS = (NLCRSMatrix*)nlCRSMatrixNewFromSparseMatrix((NLSparseMatrix*)M);
    }

    nl_assert(!(CRS->symmetric_storage));
    
    LU = NL_NEW(NLSuperLUFactorizedMatrix);
    LU->m = M->m;
    LU->n = M->n;
    LU->type = NL_MATRIX_OTHER;
    LU->destroy_func = (NLDestroyMatrixFunc)(nlSuperLUFactorizedMatrixDestroy);
    LU->mult_func = (NLMultMatrixVectorFunc)(nlSuperLUFactorizedMatrixMult);
    LU->perm_c = NL_NEW_ARRAY(int, n);
    LU->perm_r = NL_NEW_ARRAY(int, n);    

    dCreate_CompCol_Matrix(
        &superM, (int)n, (int)n, (int)nlCRSMatrixNNZ(CRS),
        CRS->val, (int*)CRS->colind, (int*)CRS->rowptr, 
        SLU_NR,              /* Row_wise, no supernode */
        SLU_D,               /* doubles                */ 
        CRS->symmetric_storage ? SLU_SYL : SLU_GE
    );

    set_default_options(&options);
    switch(solver) {
    case NL_SUPERLU_EXT: {
        options.ColPerm = NATURAL;
    } break;
    case NL_PERM_SUPERLU_EXT: {
        options.ColPerm = COLAMD;
    } break;
    case NL_SYMMETRIC_SUPERLU_EXT: {
        options.ColPerm = MMD_AT_PLUS_A;
        options.SymmetricMode = YES;
    } break;
    default: 
        nl_assert_not_reached;
    }
    
    StatInit(&stat);

    dgssv_factorize_only(
	  &options, &superM, LU->perm_c, LU->perm_r,
	  &LU->L, &LU->U, &stat, &info, &LU->trans
    );

    StatFree(&stat);
    
    /*
     * Only the "store" structure needs to be deallocated 
     * (the arrays have been allocated by us, they are in CRS).
     */
    Destroy_SuperMatrix_Store(&superM);
    
    if((NLMatrix)CRS != M) {
        nlDeleteMatrix((NLMatrix)CRS);
    }

    if(info != 0) {
	NL_DELETE(LU);
	LU = NULL;
    }
    return (NLMatrix)LU;
}
