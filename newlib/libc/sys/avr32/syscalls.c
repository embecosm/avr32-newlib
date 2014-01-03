#include "syscalls.h"
#include "sys/sysregs.h"
#include <sys/times.h>
#include <sys/time.h>
#include <stdio.h>
#include <errno.h>

int  __attribute__((weak))
     _init_startup ()
{
  return 0;
}


clock_t __attribute__((weak))
     _times( struct tms *tms )
{
  int tick;
  tick = __builtin_mfsr(SYSREG_COUNT);
  tms->tms_utime = 0;
  tms->tms_stime = tick;
  tms->tms_cutime = 0;
  tms->tms_cstime = 0;
  return tick;
}
 
extern void __heap_start__, __heap_end__;

void * __attribute__((weak))
     _sbrk(int increment)
{
  static void *cur_heap_pos = 0;

  //Initialize cur_heap_pos
  if ( cur_heap_pos == 0 )
    cur_heap_pos = &__heap_start__;
  
  if ( (cur_heap_pos + increment) <= &__heap_end__ ){
    void *heap_pos = cur_heap_pos;
    cur_heap_pos += increment;
    return heap_pos;
  } else {
#ifdef DEBUG_MSG_ON
    fprintf(stderr, "Warning: Heap is running full trying to allocate %i bytes!!!!\n", increment);
    fprintf(stderr, "\tHeap start address\t= 0x%x\n", &__heap_start__);
    fprintf(stderr, "\tHeap end address\t= 0x%x\n", &__heap_end__);
    fprintf(stderr, "\tCurrent heap address\t= 0x%x\n", cur_heap_pos);
    fflush(stderr);
#endif
    errno = ENOMEM;
    return (void *)-1;
  }  
  return (void *)-1;
}
  
void __attribute__((weak,naked))
     _init_argv (void *arg_mem_top)
{
  T2H_SYSCALL(T2H_SYSCALL_INIT_ARGV);
  T2H_SYSCALL_RETURN();
}

void __attribute__((weak,naked))
     _exit( int code )
{
  T2H_SYSCALL(T2H_SYSCALL_EXIT);
  while (1);
}

int __attribute__((weak,naked))
     _open (char *pathname, int flags, int mode)
{
  T2H_SYSCALL(T2H_SYSCALL_OPEN);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak,naked))
     _close (int file)
{
  T2H_SYSCALL(T2H_SYSCALL_CLOSE);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak,naked))
     _lseek( int filedes, int offset, int whence )
{
  T2H_SYSCALL(T2H_SYSCALL_LSEEK);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}


int __attribute__((weak,naked))
     _read (int file,
            char * ptr,
            int len){
  T2H_SYSCALL(T2H_SYSCALL_READ);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak,naked))
     _write (int file,
             char * ptr,
             int len){
  T2H_SYSCALL(T2H_SYSCALL_WRITE);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak,naked))
     isatty (int desc){ 
  T2H_SYSCALL(T2H_SYSCALL_ISATTY);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

static void _convert_host2target_stat(struct stat *target_stat, struct host_stat *host_stat)
{
  target_stat->st_dev = (dev_t)host_stat->st_dev;
  target_stat->st_ino = (ino_t)host_stat->st_ino;
  target_stat->st_mode = (mode_t)host_stat->st_mode;
  target_stat->st_nlink = (nlink_t)host_stat->st_nlink;
  target_stat->st_uid = (uid_t)host_stat->st_uid;
  target_stat->st_gid = (gid_t)host_stat->st_gid;
  target_stat->st_rdev = (dev_t)host_stat->st_rdev;
  target_stat->st_size = (off_t)host_stat->st_size;
  target_stat->st_blksize = (long)host_stat->st_blksize;
  target_stat->st_blocks = (long)host_stat->st_blocks;
  target_stat->st_atime = (time_t)host_stat->st_atime; 
  target_stat->st_mtime = (time_t)host_stat->st_mtime;
  target_stat->st_ctime = (time_t)host_stat->st_ctime;
}

int __attribute__((naked))
     _fstat_host (int filedes, struct host_stat *ptr){ 
  T2H_SYSCALL(T2H_SYSCALL_FSTAT);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((naked))
     _stat_host (const char *filename, struct host_stat *ptr){ 
  T2H_SYSCALL(T2H_SYSCALL_STAT);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak))
     _fstat (int filedes, struct stat *stat){ 
  struct host_stat host_stat;
  if ( _fstat_host (filedes, &host_stat) < 0 )
    return -1;
  _convert_host2target_stat (stat, &host_stat);
  return 0;
}

int __attribute__((weak))
     _stat (const char *filename, struct stat *stat){ 
  struct host_stat host_stat;
  if ( _stat_host (filename, &host_stat) < 0)
    return -1;
  _convert_host2target_stat (stat, &host_stat);
  return 0;
}


int __attribute__((naked))
     _gettimeofday_host (struct host_timeval *tv, struct timezone *tz){ 
  T2H_SYSCALL(T2H_SYSCALL_GETTIMEOFDAY);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak))
     _gettimeofday (struct timeval *tv, struct timezone *tz){ 
  struct host_timeval host_tv;
  if ( _gettimeofday_host (&host_tv, tz)  < 0 )
    return -1;
  tv->tv_sec = (long)host_tv.tv_sec;
  tv->tv_usec = (long)host_tv.tv_usec;
  return 0;
}

int __attribute__((weak,naked))
     _unlink (const char *path){ 
  T2H_SYSCALL(T2H_SYSCALL_UNLINK);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak,naked))
     _system (const char *command){ 
  T2H_SYSCALL(T2H_SYSCALL_SYSTEM);
  T2H_SYSCALL_CHECK_ERROR_AND_RETURN();
}

int __attribute__((weak))
     _execve (){
  return -1;
}


int __attribute__((weak))
     _fork (){ 
  return -1;
}

int __attribute__((weak))
     _wait (){ 
  return -1; 
}

int __attribute__((weak))
     sigfillset (){ 
  return -1;
}

int __attribute__((weak))
     sigprocmask (){ 
  return -1;
}

int __attribute__((weak))
     _fcntl (){ 
  return -1;
}

int __attribute__((weak))
     _link (){ 
  return -1;
}

int __attribute__((weak))
     _kill (){ 
  return -1;
}

int __attribute__((weak))
     _getpid (){
  return -1;
}
