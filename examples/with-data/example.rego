package rego

default allow = false

allow if {
    user := input.user
    data.role[user] == "admin"
}

