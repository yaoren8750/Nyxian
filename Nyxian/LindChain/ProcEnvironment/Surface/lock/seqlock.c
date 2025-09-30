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

#include <LindChain/ProcEnvironment/Surface/lock/seqlock.h>
#include <LindChain/ProcEnvironment/Surface/extra/relax.h>

_Thread_local unsigned long local_seq;

void seqlock_init(seqlock_t *s)
{
    spinlock_init(&(s->spinlock));
    __atomic_store_n(&s->seq, 0, __ATOMIC_RELAXED);
}

void seqlock_lock(seqlock_t *s)
{
    spinlock_lock(&(s->spinlock));
    __atomic_add_fetch(&s->seq, 1, __ATOMIC_RELEASE);
}

void seqlock_unlock(seqlock_t *s)
{
    spinlock_unlock(&(s->spinlock));
    __atomic_add_fetch(&s->seq, 1, __ATOMIC_RELEASE);
}

void seqlock_read_begin(const seqlock_t *s)
{
    while(1)
    {
        local_seq = __atomic_load_n(&s->seq, __ATOMIC_ACQUIRE);
        if(local_seq & 1)
        {
            do
            {
                relax();
                local_seq = __atomic_load_n(&s->seq, __ATOMIC_ACQUIRE);
            }
            while(local_seq & 1);
        }

        if(__atomic_load_n(&s->seq, __ATOMIC_ACQUIRE) == local_seq)
            return;
    }
}

bool seqlock_read_retry(const seqlock_t *s)
{
    __atomic_thread_fence(__ATOMIC_ACQUIRE);
    return __atomic_load_n(&s->seq, __ATOMIC_ACQUIRE) != local_seq;
}
