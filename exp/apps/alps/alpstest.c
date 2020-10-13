#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>

int main() {
	
	if (fork() != 0) {
		wait(NULL);
	} else {
		int pid=getpid();
		printf("child pid %u\n", pid);
		char bare_path[4096];
		getcwd(bare_path, sizeof(bare_path));
		const char *bare_exec = "alpstestbare";
		strcat(bare_path, "/");
		strcat(bare_path, bare_exec);
		printf("exec: path %s bin %s\n", bare_path, bare_exec);
		int rc = execl(bare_path, bare_exec, NULL);
		printf("exec failed: rc %d\n", rc);
	}
	return 0;
}
