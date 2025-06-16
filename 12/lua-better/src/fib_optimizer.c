// src/fib_optimizer.c

#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lopcodes.h"
#include <stdbool.h>

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

// Helper function to check if two CALL instructions call the same function
static bool are_same_function_calls(const Proto *p, int call1_pc, int call2_pc)
{
  // Look backwards from each CALL to find the preceding GETTABUP
  int gettabup1_pc = -1, gettabup2_pc = -1;

  // Find GETTABUP before first call
  for (int i = call1_pc - 1; i >= 0; i--)
  {
    if (GET_OPCODE(p->code[i]) == OP_GETTABUP &&
        GETARG_A(p->code[i]) == GETARG_A(p->code[call1_pc]))
    {
      gettabup1_pc = i;
      break;
    }
  }

  // Find GETTABUP before second call
  for (int i = call2_pc - 1; i >= call1_pc; i--)
  {
    if (GET_OPCODE(p->code[i]) == OP_GETTABUP &&
        GETARG_A(p->code[i]) == GETARG_A(p->code[call2_pc]))
    {
      gettabup2_pc = i;
      break;
    }
  }

  // If both found, check if they load the same global name
  if (gettabup1_pc >= 0 && gettabup2_pc >= 0)
  {
    return GETARG_B(p->code[gettabup1_pc]) == GETARG_B(p->code[gettabup2_pc]);
  }

  return false;
}

static bool is_fib_naive(const Proto *p)
{
  // Must take exactly 1 parameter
  if (p->numparams != 1)
    return false;

  // Look for the pattern: two calls to the same function, followed by ADD
  for (int i = 0; i < p->sizecode - 1; i++)
  {
    Instruction inst1 = p->code[i];
    if (GET_OPCODE(inst1) != OP_CALL)
      continue;

    // Find the next CALL instruction (might not be immediately next)
    for (int j = i + 1; j < p->sizecode; j++)
    {
      Instruction inst2 = p->code[j];
      if (GET_OPCODE(inst2) != OP_CALL)
        continue;

      // Check if both calls are to the same function
      // For global functions, this means both are preceded by GETTABUP
      // that loads the same global name
      if (are_same_function_calls(p, i, j))
      {
        // Now look for an ADD after the second call
        for (int k = j + 1; k < p->sizecode; k++)
        {
          if (GET_OPCODE(p->code[k]) == OP_ADD)
          {
            // Found the pattern: call same_func, call same_func, add
            return true;
          }
          // Stop if we hit another major instruction
          if (GET_OPCODE(p->code[k]) == OP_RETURN)
            break;
        }
      }
      break; // Only check the first CALL after our current one
    }
  }
  return false;
}

// Recognizer for the iterative pattern.
static bool is_fib_iter(const Proto *p)
{
  if (p->numparams != 1)
    return false;
  for (int i = 0; i < p->sizecode; i++)
  {
    if (GET_OPCODE(p->code[i]) == OP_FORLOOP)
      return true;
  }
  return false;
}

// Recognizer for the tail-call pattern.
static bool is_fib_tail(const Proto *p)
{
  if (p->numparams != 1 || p->sizep == 0)
    return false;
  for (int i = 0; i < p->sizep; i++)
  {
    Proto *inner = p->p[i];
    for (int j = 0; j < inner->sizecode; j++)
    {
      if (GET_OPCODE(inner->code[j]) == OP_TAILCALL)
        return true;
    }
  }
  return false;
}

// The main recognizer that now includes our final naive check.
static bool is_fib(const Proto *p)
{

  if (is_fib_naive(p))
    return true;
  if (is_fib_iter(p))
    return true;
  if (is_fib_tail(p))
    return true;

  return false;
}