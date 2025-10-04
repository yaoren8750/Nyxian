/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <LindChain/ProcEnvironment/environment.h>
#import <LindChain/litehook/src/litehook.h>
#import <LindChain/ProcEnvironment/cred.h>

DEFINE_HOOK(getuid, uid_t, (void))
{
    return proc_getuid(proc_object_for_pid(getpid()));
}

DEFINE_HOOK(getgid, uid_t, (void))
{
    return proc_getgid(proc_object_for_pid(getpid()));
}

DEFINE_HOOK(geteuid, uid_t, (void))
{
    return proc_getuid(proc_object_for_pid(getpid()));
}

DEFINE_HOOK(getegid, uid_t, (void))
{
    return proc_getgid(proc_object_for_pid(getpid()));
}

DEFINE_HOOK(getppid, pid_t, (void))
{
    return proc_getppid(proc_object_for_pid(getpid()));
}

DEFINE_HOOK(setuid, int, (uid_t uid))
{
    return environment_proxy_setcred(CredentialSetUID, uid);
}

DEFINE_HOOK(seteuid, int, (uid_t uid))
{
    return environment_proxy_setcred(CredentialSetEUID, uid);
}

DEFINE_HOOK(setruid, int, (uid_t uid))
{
    return environment_proxy_setcred(CredentialSetRUID, uid);
}

DEFINE_HOOK(setgid, int, (gid_t gid))
{
    return environment_proxy_setcred(CredentialSetGID, gid);
}

DEFINE_HOOK(setegid, int, (gid_t gid))
{
    return environment_proxy_setcred(CredentialSetEGID, gid);
}

DEFINE_HOOK(setrgid, int, (gid_t gid))
{
    return environment_proxy_setcred(CredentialSetEGID, gid);
}

void environment_cred_init(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(environment_is_role(EnvironmentRoleGuest))
        {
            // Getting credentials
            DO_HOOK_GLOBAL(getuid);
            DO_HOOK_GLOBAL(getgid);
            DO_HOOK_GLOBAL(geteuid);
            DO_HOOK_GLOBAL(getegid);
            DO_HOOK_GLOBAL(getppid);
            DO_HOOK_GLOBAL(setuid);
            DO_HOOK_GLOBAL(setgid);
            DO_HOOK_GLOBAL(setruid);
            DO_HOOK_GLOBAL(setrgid);
            DO_HOOK_GLOBAL(seteuid);
            DO_HOOK_GLOBAL(setegid);
        }
    });
}
