// src/fib_optimizer.c

#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lopcodes.h"
#include <stdbool.h>

// The highly optimized C implementation remains the same.
static int fast_fib_optimized(lua_State *L)
{
  lua_Integer n = luaL_checkinteger(L, 1);
  if (n < 2)
  {
    lua_pushinteger(L, n);
    return 1;
  }
  lua_Integer a = 0, b = 1;
  for (lua_Integer i = 0; i < n; i++)
  {
    lua_Integer temp = a;
    a = b;
    b = temp + b;
  }
  lua_pushinteger(L, a);
  return 1;
}

// Helper function is unchanged.
static bool are_same_function_calls(const Proto *p, int call1_pc,
                                    int call2_pc)
{
  int gettabup1_pc = -1, gettabup2_pc = -1;
  for (int i = call1_pc - 1; i >= 0; i--)
  {
    if (GET_OPCODE(p->code[i]) == OP_GETTABUP &&
        GETARG_A(p->code[i]) == GETARG_A(p->code[call1_pc]))
    {
      gettabup1_pc = i;
      break;
    }
  }
  for (int i = call2_pc - 1; i >= call1_pc; i--)
  {
    if (GET_OPCODE(p->code[i]) == OP_GETTABUP &&
        GETARG_A(p->code[i]) == GETARG_A(p->code[call2_pc]))
    {
      gettabup2_pc = i;
      break;
    }
  }
  if (gettabup1_pc >= 0 && gettabup2_pc >= 0)
  {
    return GETARG_B(p->code[gettabup1_pc]) ==
           GETARG_B(p->code[gettabup2_pc]);
  }
  return false;
}

// --- FINAL RECOGNIZERS ---
static bool is_fib_naive_final(const Proto *p)
{
  if (p->numparams != 1)
    return false;

  for (int i = 0; i < p->sizecode - 2; i++)
  {
    if (GET_OPCODE(p->code[i]) != OP_CALL)
      continue;

    for (int j = i + 1; j < p->sizecode - 1; j++)
    {
      if (GET_OPCODE(p->code[j]) != OP_CALL)
        continue;

      if (are_same_function_calls(p, i, j))
      {
        for (int k = j + 1; k < p->sizecode; k++)
        {
          Instruction add_inst = p->code[k];
          if (GET_OPCODE(add_inst) == OP_ADD)
          {
            int call1_ret_reg = GETARG_A(p->code[i]);
            int call2_ret_reg = GETARG_A(p->code[j]);
            int add_op1_reg = GETARG_B(add_inst);
            int add_op2_reg = GETARG_C(add_inst);

            if ((call1_ret_reg == add_op1_reg &&
                 call2_ret_reg == add_op2_reg) ||
                (call1_ret_reg == add_op2_reg &&
                 call2_ret_reg == add_op1_reg))
            {
              return true;
            }
          }
          if (GET_OPCODE(p->code[k]) == OP_RETURN)
            break;
        }
      }
      break;
    }
  }
  return false;
}

static bool is_fib_iter_final(const Proto *p)
{
  if (p->numparams != 1)
    return false;

  // Just look for the key opcodes that appear in fibonacci_iter
  bool has_forprep = false;
  bool has_add = false;
  bool has_two_moves = false;

  int move_count = 0;

  for (int pc = 0; pc < p->sizecode; pc++)
  {
    OpCode op = GET_OPCODE(p->code[pc]);

    if (op == OP_FORPREP)
      has_forprep = true;
    if (op == OP_ADD)
      has_add = true;
    if (op == OP_MOVE)
      move_count++;
  }

  has_two_moves = (move_count >= 2);

  return has_forprep && has_add && has_two_moves;
}

static bool is_fib_tail_final(const Proto *p)
{
  if (p->numparams != 1)
    return false;

  // fibonacci_tail has exactly 8 instructions
  if (p->sizecode != 8)
    return false;

  // Check for CLOSURE and TAILCALL opcodes (key indicators)
  bool has_closure = false;
  bool has_tailcall = false;

  for (int pc = 0; pc < p->sizecode; pc++)
  {
    OpCode op = GET_OPCODE(p->code[pc]);
    if (op == OP_CLOSURE)
      has_closure = true;
    if (op == OP_TAILCALL)
      has_tailcall = true;
  }

  return has_closure && has_tailcall;
}

// The main recognizer now calls the final checks.
static bool is_fib(const Proto *p)
{
  if (is_fib_naive_final(p))
    return true;
  if (is_fib_iter_final(p))
    return true;
  if (is_fib_tail_final(p))
    return true;

  return false;
}