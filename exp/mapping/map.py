import sys
import numpy as np

NUM_TASKS=int(sys.argv[1])
PE_TIMES=np.array([float(x) for x in sys.argv[2:]])

NUM_PES=len(PE_TIMES)
CAPACITY=np.max(PE_TIMES)*NUM_TASKS

sched = np.zeros(NUM_PES)

for task_i in range(NUM_TASKS):
    worst_fit_pe = np.argmax(CAPACITY - (sched + PE_TIMES))
    sched[worst_fit_pe] += PE_TIMES[worst_fit_pe]

t_wff = np.max(sched)

def opt_sched(sched, num_tasks):
    if num_tasks == 0:
        return np.max(sched)
    t_min = CAPACITY
    for pe_i in range(NUM_PES):
        sched[pe_i] += PE_TIMES[pe_i]
        t_min = min(t_min, opt_sched(sched, num_tasks - 1))
        sched[pe_i] -= PE_TIMES[pe_i]
    return t_min

t_opt = opt_sched(np.zeros(NUM_PES), NUM_TASKS)
print("wff / opt = %f / %f = %f" % (t_wff, t_opt, t_wff / t_opt))
