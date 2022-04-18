
#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void test_kill() {
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
            sleep(4);
        }
    }
    else{
        sleep(12);
        killsystem();
    }
}

void test_pause(int seconds) {
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
            sleep(4);
        }
    }
    else{
        sleep(12);
        pausesystem(seconds);
    }
}



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

void check(){
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


// void set_economic_mode_dem(int interval, int loop_size) {
//     int pid = getpid();
//     set_economic_mode(1);
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("set economic mode %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             set_economic_mode(0);
//         }
//     }
//     printf("\n");
// }

int
main(int argc, char *argv[])
{
    // set_economic_mode_dem(10, 100);
    check();
    exit(0);
    pause_system_dem(10, 10, 100);
    kill_system_dem(10, 100);
    exit(0);
}
