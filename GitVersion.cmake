find_package(Git)
if(NOT GIT_FOUND)
    message(FATAL_ERROR "Git not found!")
else()
    # try to get last tag from git and set VERSION_STRING to it
    execute_process(COMMAND ${GIT_EXECUTABLE} describe --abbrev=0 --tags --match "v[0-9]*.[0-9]*"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE PROJECT_VERSION_STRING
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE TAG_STATUS
        )
    if(TAG_STATUS AND NOT TAG_STATUS EQUAL 0) # no tag found
        message(STATUS "No git tags found!")
        unset(GIT_TAG_FOUND)
    else() # a tag was found
        # try to parse the tag
        string(REGEX MATCHALL "[0-9]+|-(.*).([0-9]+)$" PARTIAL_VERSION_LIST ${PROJECT_VERSION_STRING})
        list(LENGTH PARTIAL_VERSION_LIST PARTIAL_VERSION_LIST_LEN)
        if(PARTIAL_VERSION_LIST_LEN LESS 2) # does not match Major.Minor pattern
            message(STATUS "Couldn't read any version number from the last tag.")
            unset(GIT_TAG_FOUND)
        else()
            list(GET PARTIAL_VERSION_LIST 0 PROJECT_VERSION_MAJOR)
            list(GET PARTIAL_VERSION_LIST 1 PROJECT_VERSION_MINOR)
            message(STATUS "Retrieved git version tag: ${PROJECT_VERSION_STRING}")
            set(GIT_TAG_FOUND TRUE)
        endif()
    endif()
endif()

if(GIT_TAG_FOUND) # parse the rest of git info
    unset(GIT_TAG_FOUND)
    unset(PARTIAL_VERSION_LIST)
    # set main branch
    set(GIT_MAIN_BRANCH "main")
    # get number of commits since last tag
    execute_process(COMMAND ${GIT_EXECUTABLE} rev-list ${PROJECT_VERSION_STRING}..HEAD --count
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE PROJECT_VERSION_PATCH
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    # get current branch
    execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE PROJECT_VERSION_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(PROJECT_VERSION_SHA 0)
    if(${PROJECT_VERSION_BRANCH} STREQUAL ${GIT_MAIN_BRANCH})
        # we are on main branch, mark version as stable
        set(WORKTREE_POSTFIX "${WORKTREE_POSTFIX}-stable")
    else()
        # we are on dev branch, mark version as dev and add current commit SHA
        execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE PROJECT_VERSION_COMMIT_SHA
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(WORKTREE_POSTFIX "${WORKTREE_POSTFIX}-dev-{PROJECT_VERSION_COMMIT_SHA}")
    endif()
    message(STATUS "Build from ${PROJECT_VERSION_BRANCH} branch!")

    # find if there are any unstaged changes
    execute_process(COMMAND ${GIT_EXECUTABLE} diff HEAD --stat
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE DIFF_STAT)
    if(DIFF_STAT)
        set(WORKTREE_POSTFIX "${WORKTREE_POSTFIX}-dirty")
    endif()
    # Tweak version has space for customization
    # e.g. may be set to number of commits on dev branch or passed from upper-level project   
    if(NOT DEFINED SET_TWEAK_VERSION) 
        set(PROJECT_VERSION_TWEAK 0)
    else()
        set(PROJECT_VERSION_TWEAK ${SET_TWEAK_VERSION})
    endif()
    # Build VERSION_STRING_FULL from VERSION_STRING and git metadata
    set(PROJECT_VERSION_MMP
        ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${PROJECT_VERSION_TWEAK})
    set(PROJECT_VERSION_STRING_FULL
        ${PROJECT_VERSION_MMP}${WORKTREE_POSTFIX})
    message(STATUS "Full project version: ${PROJECT_VERSION_STRING_FULL}")
endif()

configure_file(${CMAKE_SOURCE_DIR}/version.h.in ${OUTPUT_DIR}/version.h @ONLY)
