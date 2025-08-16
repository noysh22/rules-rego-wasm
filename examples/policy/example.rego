package rego

default allow = false

allow if {
  input.user == "alice"
}

