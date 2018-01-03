import core.stdc.stdlib;
import std.bigint;
import std.math;
import std.string;
import std.typecons;
import std.stdio;

import runtime : Context;

static const long WORD_SIZE = 64;
static const int HEADER_TAG_WIDTH = WORD_SIZE / 8;

struct Value {
  long header;
  long data;
}

enum ValueTag {
  Nil,
  Integer,
  Bool,
  BigInteger,
  String,
  Symbol,
  List,
  Vector,
  Function,
}

ValueTag tagOfValue(ref Value v) {
  return cast(ValueTag)(v.header & (pow(2, HEADER_TAG_WIDTH) - 1));
}

bool isValue(ref Value v, ValueTag vt) {
  return tagOfValue(v) == vt;
}

bool valueIsNil(ref Value v) { return isValue(v, ValueTag.Nil); }

Value nilValue = { data: 0, header: ValueTag.Nil };

Value makeIntegerValue(long i) {
  Value v = { data: i, header: ValueTag.Integer };
  return v;
}

bool valueIsInteger(ref Value v) { return isValue(v, ValueTag.Integer); }

long valueToInteger(ref Value v) {
  return cast(long)v.data;
}

Value zeroValue = makeIntegerValue(0);

Value makeBoolValue(bool b) {
  Value v = { data: b, header: ValueTag.Bool };
  return v;
}

bool valueIsBool(ref Value v) { return isValue(v, ValueTag.Bool); }

bool valueToBool(ref Value v) {
  return cast(bool)v.data;
}

Value makeBigIntegerValue(BigInt i) {
  Value v = { data: cast(long)new BigInt(i), header: ValueTag.BigInteger };
  return v;
}

bool valueIsBigInteger(ref Value v) { return isValue(v, ValueTag.BigInteger); }

BigInt valueToBigInteger(ref Value v) {
  return *cast(BigInt*)v.data;
}

static const long MAX_VALUE_LENGTH = (long.sizeof * 8) - 1;

Tuple!(void*, ulong) copyString(string s) {
  ulong size = s.length + 1 > MAX_VALUE_LENGTH ? MAX_VALUE_LENGTH : s.length + 1;

  auto heapString = new char[size];
  foreach (i, c; s[0 .. size - 1]) {
    heapString[i] = c;
  }
  heapString[size - 1] = '\0';
  return Tuple!(void*, ulong)(cast(void*)heapString, size);
}

Value makeStringValue(string s) {
  auto string = copyString(s);
  Value v = { data: cast(long)string[0], header: string[1] << HEADER_TAG_WIDTH | ValueTag.String };
  return v;
}

bool valueIsString(ref Value v) { return isValue(v, ValueTag.String); }

string valueToString(ref Value v) {
  return fromStringz(cast(char*)v.data).dup;
}

Value makeSymbolValue(string s) {
  Value v = makeStringValue(s);
  v.header >>= HEADER_TAG_WIDTH;
  v.header <<= HEADER_TAG_WIDTH;
  v.header |= ValueTag.Symbol;
  return v;
}

bool valueIsSymbol(ref Value v) { return isValue(v, ValueTag.Symbol); }

string valueToSymbol(ref Value v) {
  return valueToString(v);
}

Value makeListValue(ref Value head, ref Value tail) {
  Value v;
  v.header = ValueTag.List;
  Value** tuple = cast(Value**)malloc((Value*).sizeof * 2);
  foreach (i, item; [head, tail]) {
    tuple[i] = new Value;
    tuple[i].header = item.header;
    tuple[i].data = item.data;
  }
  v.data = cast(long)tuple;
  return v;
}

bool valueIsList(ref Value v) { return isValue(v, ValueTag.List); }

Tuple!(Value, Value) valueToList(Value v) {
  Value** m = cast(Value**)v.data;
  return Tuple!(Value, Value)(*m[0], *m[1]);
}

Value makeVectorValue(Value[] v) {
  ulong size = v.length > MAX_VALUE_LENGTH ? MAX_VALUE_LENGTH : v.length;
  Value ve = { data: cast(long)v.ptr, header: size << HEADER_TAG_WIDTH | ValueTag.Vector };
  return ve;
}

bool valueIsVector(ref Value v) { return isValue(v, ValueTag.Vector); }

Value[] valueToVector(ref Value v) {
  return *cast(Value[]*)v.data;
}

Value makeFunctionValue(string name, Value delegate(Value, Context) f, bool special) {
  void* namePtr = copyString(name)[0];
  Value v;
  v.header = ValueTag.Function;
  long* tuple = cast(long*)malloc((long).sizeof * 3);
  tuple[0] = cast(long)namePtr;
  tuple[0] <<= HEADER_TAG_WIDTH;
  tuple[0] |= cast(int)special;
  tuple[1] = cast(long)f.ptr;
  tuple[2] = cast(long)f.funcptr;
  v.data = cast(long)tuple;
  return v;
}

bool valueIsFunction(ref Value v) { return isValue(v, ValueTag.Function); }

Tuple!(string, Value delegate(Value, Context), bool) valueToFunction(ref Value v) {
  Value delegate(Value, Context) f;
  long* tuple = cast(long*)v.data;
  bool special = cast(bool)(tuple[0] & (pow(2, HEADER_TAG_WIDTH) - 1));
  void* namePtr = cast(void*)(tuple[0] >> HEADER_TAG_WIDTH);
  string name = fromStringz(cast(char*)namePtr).dup;
  f.ptr = cast(void*)tuple[1];
  f.funcptr = cast(Value function(Value, Context))(tuple[2]);
  return Tuple!(string, Value delegate(Value, Context), bool)(name, f, special);
}