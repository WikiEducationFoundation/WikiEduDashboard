#!/usr/bin/env bash

RED=$'\e[31m'
GREEN=$'\e[32m'
NORMAL=$'\e[0m'

print_error() {
  printf "$RED$1$NORMAL\n"
}

print_success() {
  printf "$GREEN$1$NORMAL\n"
}
