# Shell used by make to exectute commands (must be first)
#
SHELL = /bin/sh

# These variables make things verbose or not
#
ifeq ($(VERBOSE), 1)
                   ATECHO := @true \#
                   ATSIGN :=
else
                   ATECHO := @echo
                   ATSIGN := @
endif

# Common commands
#
ECHO := echo

GRADLE_ARGS ?= --info
GRADLE = ../gradlew $(GRADLE_ARGS)

#
# compiler, tools and flags
#
# archival tool
AR      := /usr/bin/pixz
ARFLAGS := -e9

# mkdir command
MKDIR := mkdir --parents

# file/dir. removal
RM := rm --recursive --force

# docker command
DOCKER := /usr/bin/docker

#
# version
#
MAJOR            := 3
MINOR            := 7
SP               := 0
PATCH            := 0
PRODUCT_VERSION  ?= ${MAJOR}.${MINOR}.${SP}.${PATCH}
BUILD_REL_A      := $(shell git rev-list HEAD | wc -l)
BUILD_REL_B      := $(shell git rev-parse --short HEAD)
BLD_CNT          := $(shell echo ${BUILD_REL_A})
BLD_SHA          := $(shell echo ${BUILD_REL_B})
RELEASE_STR      := ${BLD_CNT}.${BLD_SHA}
FULL_VERSION     := ${PRODUCT_VERSION}-${RELEASE_STR}
# only for /etc/ecs_release file
ECS_RELEASE      := ${PRODUCT_VERSION}.${RELEASE_STR}

#
# directories
#
SRC_DIR          := src
BUILD_DIR        := build
BIN_DIR          := ${BUILD_DIR}/bin
LIBS_DIR         := ${BUILD_DIR}/libs
DOCKER_DIR       := docker

#
# docker
#
BOOKKEEPER_REPO       := BOOKKEEPER_REPO
BOOKKEEPER_REPO_TAG        := ${FULL_VERSION}
BOOKKEEPER_REPO_REPO_TAG   := ${BOOKKEEPER_REPO_REPO}:${BOOKKEEPER_REPO_TAG}
