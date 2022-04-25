
#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"


void pause_system_dem(int interval, int pause_seconds, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            pausesystem(pause_seconds);
        }
    }
    printf("\n");
}

void kill_system_dem(int interval, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            killsystem();
        }
    }
    printf("\n");
}

void Scheduling_validator(){
    int n_forks = 4;
    int pid;
    int k;
    for (int i = 0; i < n_forks; i++) {
    	pid = fork();
        if(pid == 0)
        {
        k = i;
        break;
        }
    }
    if(pid==0){
        while(1){
            printf("this is process %d\n", k);
        }
    }
}

void env(int size, int interval, char* env_name) {
    int result = 1;
    int loop_size = 10e6;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
       pid = fork();
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % (loop_size / (int) 10e0) == 0) {
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
        	}
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
  
}

void env_large() {
    env(10e6, 10e6, "env_large");
}

void env_freq() {
    env(10e1, 10e1, "env_freq");
}

void PauseKillTest(int a, int b, int c, int d, int e){
    pause_system_dem(a,b,c);
    kill_system_dem(d,e);
}

int
main(int argc, char *argv[])
{
    // PauseKillTest(10,3,100,10,100);
    // Scheduling_validator();
    // test_pause();
    // env_large();
    env_freq();
    print_stats();
    exit(0);
}