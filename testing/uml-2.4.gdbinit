# These two gdb user defined commands might help you to unterstand
# kernel lockups. 
# Use these functions on a GDB running User Mode Linux in SKAS mode.
#
# You can load this file into GDB by using the 'source' command,
# or simply put it into your .gdbinit
#
# This works in my environment of (Debian Woody 3.0):
#  binutils         2.12.90.0.1-4
#  gcc              2.95.4-14
#  gdb              5.2.cvs20020401-6
#  linux            2.4.22
#  uml              uml-patch-2.4.22-1   
#
# I experienced serious troubles using Debian Sid Packages...
#  * gdb crashing
#  * gdb printing bogus stack traces
#  * uml kernel crashing in strange places 
#  * strange behaviour
#
# -Philipp


define linux-bt
  set $bt_switch_buf = ((struct task_struct*)$arg0)->thread.mode.skas.switch_buf
  set $bt_ebp = ((unsigned long*)$bt_switch_buf)[3]
  set $bt_i = 0
  printf "-#-  ---EBP----  ---EIP----    ---------FUNCTION---------\n"
  while $bt_i < 32
    set $bt_eip = ((unsigned long*)$bt_ebp)[1]
    if $bt_eip == __restore
      set $bt_i = 32
    else 
      printf "#%-2d  0x%8x  0x%8x in ", $bt_i, $bt_ebp, $bt_eip
      info symbol $bt_eip
      set $bt_ebp = ((unsigned long*)$bt_ebp)[0]
      set $bt_i = $bt_i + 1
    end
  end
end

document linux-bt
  linux-bt takes the address of a task_struct as argument,
  and prints the stack back trace of that task.
  You might use linux-ps to find the addresses of all available
  tasks on the system
end

define linux-ps
  set $ps_i=0
  printf "---TASK---  -PID-  --------COMM----------\n"
  while $ps_i < 1024
    set $ps_p = pidhash[$ps_i]
      while $ps_p
        printf "0x%8x  %-5d  %-20s\n", $ps_p, $ps_p->pid, $ps_p->comm
        set $ps_p = $ps_p->pidhash_next
      end
    set $ps_i = $ps_i + 1
  end
end

document linux-ps
  linux-ps lists all tasks on the system. 
  Also have a look at linux-bt.
end

define linux-mod-helper
  p/x (int)module_list+(int)module_list->size_of_struct
end

define drbd-al-show
  set $sa_base = &((struct Drbd_Conf *)$arg0)->act_log
  lru-show $sa_base
end

define lru-show
  set $ls_nr=((struct lru_cache *)$arg0)->nr_elements
  set $ls_elements=(void *) (((struct lru_cache *)$arg0)->slot + $ls_nr)
  set $ls_esize=((struct lru_cache *)$arg0)->element_size
  printf "-#-  ---ADDR---  -EXTENT-  -HASH-NEXT-   TABLE\n"
  set $ls_i=0
  while $ls_i < $ls_nr
    set $ls_element = (struct lc_element *)($ls_elements + $ls_i * $ls_esize)
    printf "%3d  0x%8x  %8d ", $ls_i, $ls_element, $ls_element->lc_number
    if $ls_element->colision.next
      printf "  %3d", ((void *)$ls_element->colision.next - $ls_elements)/$ls_esize
    end
    printf "\n"
    set $ls_i = $ls_i + 1    
  end
  printf "-#-  -TABLE-#-  -EXTENT-   LRU LIST\n"
  set $ls_le=((struct lru_cache *)$arg0)->lru->next
  set $ls_i=0
  while $ls_le != &((struct lru_cache *)$arg0)->lru && $ls_i < $ls_nr
    set $ls_e = (struct lc_element *)(((char *)$ls_le)-8)
    set $ls_en = ((void*)$ls_e-$ls_elements)/$ls_esize
    printf "%3d  %8d  %8d\n", $ls_i, $ls_en, $ls_e->lc_number
    set $ls_i = $ls_i + 1
    set $ls_le = $ls_le->next    
  end
end
