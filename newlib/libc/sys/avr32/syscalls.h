#ifndef __SYSCALLS_H__
#define __SYSCALLS_H__

#include <sys/stat.h>
#include <errno.h>

struct host_stat {
  unsigned int       st_dev;      /* device */
  unsigned int       st_ino;      /* inode */
  mode_t             st_mode;     /* protection */
  unsigned int       st_nlink;    /* number of hard links */
  unsigned int       st_uid;      /* user ID of owner */
  unsigned int       st_gid;      /* group ID of owner */
  unsigned int       st_rdev;     /* device type (if inode device) */
  unsigned long long st_size;     /* total size, in bytes */
  unsigned long long st_blksize;  /* blocksize for filesystem I/O */
  unsigned long long st_blocks;   /* number of blocks allocated */
  time_t             st_atime;    /* time of last access */
  time_t             st_mtime;    /* time of last modification */
  time_t             st_ctime;    /* time of last change */
};

struct host_timeval {
  time_t tv_sec;
  long long tv_usec;
};


#define T2H_SYSCALL_OPEN                1
#define T2H_SYSCALL_CLOSE               2
#define T2H_SYSCALL_READ                3
#define T2H_SYSCALL_WRITE               4
#define T2H_SYSCALL_LSEEK               5
#define T2H_SYSCALL_RENAME              6
#define T2H_SYSCALL_UNLINK              7
#define T2H_SYSCALL_STAT                8
#define T2H_SYSCALL_FSTAT               9
#define T2H_SYSCALL_GETTIMEOFDAY        10
#define T2H_SYSCALL_ISATTY              11
#define T2H_SYSCALL_SYSTEM              12
#define T2H_SYSCALL_EXIT                13
#define T2H_SYSCALL_INIT_ARGV           14


/* The breakpoint/mov r12,-1/mov r11,... pattern causes
   the debugger to be able to recognize the system call. 
   If the debug system is not enabled then the breakpoint 
   is executed as a nop and r12 set to -1 and errno to 
   ENOSYS. The debugger is responsible for setting r12
   and r11 and skipping the instructions after the breakpoint
   which would otherwise set these registers.
*/    
#define T2H_SYSCALL(syscall_code)                 \
  asm ("mov   r8, %0\n"                           \
       "breakpoint\n"                             \
       "mov   r12, -1\n"                          \
       "mov   r11, %1\n"                          \
       :: "i" (syscall_code), "i" (ENOSYS) );

#define T2H_SYSCALL_CHECK_ERROR_AND_RETURN()                            \
  asm ("cp.w  r12, 0\n"                                                 \
       "retge r12\n"                                                    \
       "lda.w r10, errno\n"                                             \
       "st.w  r10[0], r11\n"                                            \
       "ret   r12\n"                                                    \
       ".align 2\n"                                                     \
       ".cpool\n");

#define T2H_SYSCALL_RETURN()                                       \
  asm ("ret  r12\n");                                            

#endif
