import resource

# global, we want a singleton for easy of use from any source file in any
# package, and there's no point in wrapping this in a class.
measurements = {}

def save(name, time_s, rank, mem=False):
	measurements[name] = time_s
	if mem:
		# getrusage units are in KB (according to manpage)
		measurements[name + "_peak_mem_mb"] = \
			resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024

def items():
	return measurements.items()
