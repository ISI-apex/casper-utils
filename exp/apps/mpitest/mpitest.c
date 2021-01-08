#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <unistd.h>

int main (int argc, char *argv[])
{
	int i, rank, size, namelen;
	char name [MPI_MAX_PROCESSOR_NAME];
	char hostname[32] = {0};
	size_t rc;
	size_t len = 0;

#ifdef WAIT_FOR_DEBUGGER
	{
		volatile int i = 0;
		char hostname[256];
		gethostname(hostname, sizeof(hostname));
		printf("PID %d on %s ready for attach\n", getpid(), hostname);
		fflush(stdout);
		while (0 == i)
			sleep(5);
	}
#endif

	//val=getenv("hostname");
	FILE* fhost = popen("hostname",  "r");
	if ((rc = fread(hostname, sizeof(hostname) - 1, 1, fhost)) == 0) {
		if (ferror(fhost)) {
			perror("ERROR: failed to get hostanem from 'hostname'");
			pclose(fhost);
			return 1;
		} else if (feof(fhost) && (len = strlen(hostname)) == 0) {
			perror("ERROR: empty output from 'hostname'");
			pclose(fhost);
			return 1;
		}  /* feof() but filled buffer: success */
	}
	--len;
	while(hostname[len] == '\n' || hostname[len] == ' ' || hostname[len] == '\t')
		hostname[len--] = '\0';
	pclose(fhost);

	printf("host %s: initing MPI...\n", hostname);

#ifdef SLEEP
	sleep(30);
#endif

	MPI_Init (&argc, &argv);

	MPI_Comm_size (MPI_COMM_WORLD, &size);
	MPI_Comm_rank (MPI_COMM_WORLD, &rank);
	MPI_Get_processor_name (name, &namelen);

	if (rank == 0 )
		printf ("MPI World size = %d processes\n", size);

	printf ("Hello World from rank %d running on %s (hostname %s)!\n", rank, name, hostname);

	static int data[1] = {0};
	if (rank == 0) {
		data[0] = 42;
		printf("rank %u: broadcasting data %d!\n", rank, data[0]);
	}
	MPI_Bcast(data, 1, MPI_INT, 0, MPI_COMM_WORLD);
	if (rank != 0) {
		printf("rank %u: received bcast data %d!\n", rank, data[0]);
	}

	MPI_Finalize ();
}
