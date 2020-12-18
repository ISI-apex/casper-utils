# Stokes Equations
# ================
#
# A simple example of a saddle-point system, we will use the Stokes
# equations to demonstrate some of the ways we can do field-splitting
# with matrix-free operators.  We set up the problem as a lid-driven
# cavity.
#
# As ever, we import firedrake and define a mesh.::

import os
import sys
import time

N = 64
SOLVER = "superlu_dist"
GPU = 0
THREADS = 1

# Must be before importing firedrake!
os.environ["OMP_NUM_THREADS"] = str(THREADS)

from firedrake import *

def generate():
    raise Exception("Not implemented")

def solve_cavity(res):

    print("START: mesh", N, "solver", SOLVER, "threads", THREADS, "gpu", GPU, "...")
    start_time = time.time()

    M = UnitSquareMesh(N, N)
    #M = DeciSquareMesh(N, N)

    V = VectorFunctionSpace(M, "CG", 2)
    W = FunctionSpace(M, "CG", 1)
    Z = V * W

    u, p = TrialFunctions(Z)
    v, q = TestFunctions(Z)

    a = (inner(grad(u), grad(v)) - p * div(v) + div(u) * q)*dx

    L = inner(Constant((0, 0)), v) * dx

    # The boundary conditions are defined on the velocity space.  Zero
    # Dirichlet conditions on the bottom and side walls, a constant :math:`u
    # = (1, 0)` condition on the lid.::

    bcs = [DirichletBC(Z.sub(0), Constant((1, 0)), (4,)),
           DirichletBC(Z.sub(0), Constant((0, 0)), (1, 2, 3))]

    up = Function(Z)

    # Since we do not specify boundary conditions on the pressure space, it
    # is only defined up to a constant.  We will remove this component of
    # the solution in the solver by providing the appropriate nullspace.::

    nullspace = MixedVectorSpaceBasis(
        Z, [Z.sub(0), VectorSpaceBasis(constant=True)])

    # First up, we will solve the problem directly.  For this to work, the
    # sparse direct solver MUMPS must be installed.  Hence this solve is
    # wrapped in a ``try/except`` block so that an error is not raised in
    # the case that it is not, to do this we must import ``PETSc``::

    from firedrake.petsc import PETSc

    # To factor the matrix from this mixed system, we must specify
    # a ``mat_type`` of ``aij`` to the solve call.::

    #try:
    #typedef enum pastix_scheduler_e {
    #            PastixSchedSequential = 0, /**< Sequential                           */
    #            PastixSchedStatic     = 1, /**< Shared memory with static scheduler  */
    #            PastixSchedParsec     = 2, /**< PaRSEC scheduler                     */
    #            PastixSchedStarPU     = 3, /**< StarPU scheduler                     */
    #            PastixSchedDynamic    = 4, /**< Shared memory with dynamic scheduler */
    #            } pastix_scheduler_t;

    solve(a == L, up, bcs=bcs, nullspace=nullspace,
          solver_parameters={
                            #"ksp_type": "gmres",
                            "ksp_type": "preonly",
                            #"ksp_gmres_haptol": 1e-2,
                            #"ksp_type": "cg",
                             #"ksp_atol": 1e-2,
                             #"ksp_rtol": 1e-1,

                             #"ksp_atol": 1e-4,
                             #"ksp_rtol": 1e-3,

                             "mat_type": "aij",
                             "pc_type": "lu",

                             #"pc_factor_mat_solver_type": "mumps",

                             #"pc_factor_mat_solver_type": "superlu_dist",

                             #"pc_factor_mat_solver_type": "pastix",

                             "pc_factor_mat_solver_type": SOLVER,

                             "mat_pastix_verbose": 2,
                             "mat_pastix_scheduler": 3,
                             #"mat_pastix_itermax": 1,
                             #"mat_pastix_gmresim": 50,
                             "mat_pastix_refinement": -1,
                             #"mat_pastix_epsilonrefinement": 1e-6,
                             #"mat_pastix_threadnbr": ((GPU + 1) % 2),
                             "mat_pastix_threadnbr": THREADS,
                             "mat_pastix_gpunbr": GPU,
                             })
    end_time = time.time()
    print("EXEC TIME (sec): mesh", N, "solver", SOLVER, "threads", THREADS, "gpu", GPU, ":", end_time - start_time)
    #except PETSc.Error as e:
    #    if e.ierr == 92:
    #        warning("MUMPS not installed, skipping direct solve")
    #    else:
    #        raise e

    print(type(up))
    u, p = up.split()
    u.rename("Velocity")
    p.rename("Pressure")
    print(type(u))
    print(type(u.vector()))
    print(u.vector())
    # Return results by adding them to the passed dict object
    res["u"] = u
    res["p"] = p

## Now we'll use a Schur complement preconditioner using unassembled
## matrices.  We can do all of this purely by changing the solver
## options.  We'll define the parameters separately to run through the
## options.::
#
#parameters = {
#
## First up we select the unassembled matrix type::
#
#    "mat_type": "matfree",
#
## Now we configure the solver, using GMRES using the diagonal part of
## the Schur complement factorisation to approximate the inverse.  We'll
## also monitor the convergence of the residual, and ask PETSc to view
## the configured Krylov solver object.::
#
#    "ksp_type": "gmres",
#    "ksp_monitor_true_residual": None,
#    "ksp_view": None,
#    "pc_type": "fieldsplit",
#    "pc_fieldsplit_type": "schur",
#    "pc_fieldsplit_schur_fact_type": "diag",
#
## Next we configure the solvers for the blocks.  For the velocity block,
## we use an :class:`.AssembledPC` and approximate the inverse of the
## vector laplacian using a single multigrid V-cycle.::
#
#    "fieldsplit_0_ksp_type": "preonly",
#    "fieldsplit_0_pc_type": "python",
#    "fieldsplit_0_pc_python_type": "firedrake.AssembledPC",
#    "fieldsplit_0_assembled_pc_type": "hypre",
#
## For the Schur complement block, we approximate the inverse of the
## schur complement with a pressure mass inverse.  For constant viscosity
## this works well.  For variable, but low-contrast viscosity, one should
## use a viscosity-weighted mass-matrix.  This is achievable by passing a
## dictionary with "mu" associated with the viscosity into solve.  The
## MassInvPC will choose a default value of 1.0 if not set.  For high viscosity
## contrasts, this preconditioner is mesh-dependent and should be replaced
## by some form of approximate commutator.::
#
#    "fieldsplit_1_ksp_type": "preonly",
#    "fieldsplit_1_pc_type": "python",
#    "fieldsplit_1_pc_python_type": "firedrake.MassInvPC",
#
## The mass inverse is dense, and therefore approximated with a Krylov
## iteration, which we configure now::
#
#    "fieldsplit_1_Mp_ksp_type": "preonly",
#    "fieldsplit_1_Mp_pc_type": "ilu"
# }
#
## Having set up the parameters, we can now go ahead and solve the
## problem.::
#
#up.assign(0)
#solve(a == L, up, bcs=bcs, nullspace=nullspace, solver_parameters=parameters)

# Last, but not least, we'll write the solution to a file for later
# visualisation.  We split the function into its velocity and pressure
# parts and give them reasonable names, then write them to a paraview
# file.::

#u, p = up.split()
#u.rename("Velocity")
#p.rename("Pressure")
#
#File("stokes.pvd").write(u, p)

## By default, the mass matrix is assembled in the :class:`~.MassInvPC`
## preconditioner, however, this can be controlled using a ``mat_type``
## argument.  To do this, we must specify the ``mat_type`` inside the
## preconditioner.  We can use the previous set of parameters and just
## modify them slightly. ::
#
#parameters["fieldsplit_1_Mp_mat_type"] = "matfree"
#
## With an unassembled matrix, of course, we are not able to use standard
## preconditioners, so for this example, we will just invert the mass
## matrix using unpreconditioned conjugate gradients. ::
#
#parameters["fieldsplit_1_Mp_ksp_type"] = "cg"
#parameters["fieldsplit_1_Mp_pc_type"] = "none"
#
#up.assign(0)
#solve(a == L, up, bcs=bcs, nullspace=nullspace, solver_parameters=parameters)
#
# A runnable python script implementing this demo file is available
# `here <stokes.py>`__.

def save_sol(sol):
    print("velocity:", sol["u"])
    print("pressure:", sol["p"])
    #File("stokes.pvd").write(sol["u"], sol["p"])
