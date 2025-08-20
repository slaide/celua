return {
    source_dir = "src",
    build_dir = "build", 
    gen_target = "5.1",
    scripts = {
        build = {
            post = "scripts/create_executable.tl",
        },
    },
}