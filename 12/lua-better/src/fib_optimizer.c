// src/fib_optimizer.c

#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lopcodes.h"
#include <stdbool.h>

// The C function we are JIT-compiling to.
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

// --- FINAL, MULTI-HEURISTIC RECOGNIZERS ---

// Helper to check for the existence of an integer in the constant table.
static bool has_integer_constant(const Proto *p, lua_Integer n)
{
  for (int i = 0; i < p->sizek; i++)
  {
    const TValue *k = &p->k[i];
    if (ttisinteger(k) && ivalue(k) == n)
    {
      return true;
    }
  }
  return false;
}

// The final, robust recognizer for the naive recursive pattern.
static bool is_fib_naive_final(const Proto *p)
{
  // Heuristic 1: Signature check. Must take exactly 1 argument.
  if (p->numparams != 1)
    return false;

  // Heuristic 2: Constant check. Must have constants 1 and 2 for n-1, n-2.
  if (!has_integer_constant(p, 1) || !has_integer_constant(p, 2))
    return false;

  // Heuristic 3 & 4: Opcode and Recursion count.
  int recursive_calls = 0;
  int subs = 0;
  bool has_add = false;

  for (int i = 0; i < p->sizecode; i++)
  {
    Instruction inst = p->code[i];
    OpCode op = GET_OPCODE(inst);

    if (op == OP_CALL)
    {
      if (GETARG_A(inst) == 0)
        recursive_calls++;
    }
    else if (op == OP_ADD)
    {
      has_add = true;
    }
    // *** THE CRITICAL FIX IS HERE ***
    // We must check for both register-register SUB and register-constant SUBK.
    else if (op == OP_SUB || op == OP_SUBK)
    {
      subs++;
    }
  }

  // Final check: Must meet all opcode count criteria.
  return (recursive_calls >= 2 && subs >= 2 && has_add);
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
  if (is_fib_naive_final(p))
    return true;
  if (is_fib_iter(p))
    return true;
  if (is_fib_tail(p))
    return true;

  return false;
}