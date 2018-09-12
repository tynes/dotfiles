function chmod_help() {
    echo "----------	0000	no permissions"
    echo "-rwx------	0700	read, write, & execute only for owner"
    echo "-rwxrwx---	0770	read, write, & execute for owner and group"
    echo "-rwxrwxrwx	0777	read, write, & execute for owner, group and others SECURITY RISK"
    echo "---x--x--x	0111	execute"
    echo "--w--w--w-	0222	write"
    echo "--wx-wx-wx	0333	write & execute"
    echo "-r--r--r--	0444	read"
    echo "-r-xr-xr-x	0555	read & execute"
    echo "-rw-rw-rw-	0666	read & write"
    echo "-rwxr-----	0740	owner can read, write, & execute; group can only read; others have no permissions"
}
