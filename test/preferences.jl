using Test
using Libxc

@testset "GPU library path preferences" begin
    project_dir = dirname(dirname(@__FILE__))
    julia = Base.julia_cmd()

    function gpu_path_in_subprocess()
        script = """
            using Libxc
            path = Libxc.gpu_libxc_path()
            println(isnothing(path) ? "nothing" : path)
        """
        readchomp(`$julia --project=$project_dir -e $script`)
    end

    # Setting a non-existent path should error
    @test_throws ErrorException Libxc.set_gpu_libxc_path!("/nonexistent/libxc.so")

    # Setting an existing file should work
    tmpfile = tempname() * ".so"
    touch(tmpfile)
    try
        Libxc.set_gpu_libxc_path!(tmpfile)
        @test gpu_path_in_subprocess() == tmpfile
    finally
        rm(tmpfile; force=true)
    end

    # Unsetting the preference should fall back to Libxc_GPU_jll
    Libxc.set_gpu_libxc_path!(nothing)
    expected = readchomp(`$julia --project=$project_dir -e "
        using Libxc
        using Libxc_GPU_jll
        path = Libxc.gpu_libxc_path()
        println(isnothing(path) ? \"nothing\" : path)
    "`)
    @test gpu_path_in_subprocess() == expected
end
