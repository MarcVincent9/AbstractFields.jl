using AbstractFields
using Test

macro testall(T, fields, types)
name = "$T"
quote
    @testset $name begin
        @test fieldnames($T) == $fields
        for (index, field) in enumerate($fields)
            @test fieldname($T, index) === field
            @test hasfield($T, field)
        end
        @test fieldcount($T) == length($fields)
        @test $T.types == $types
    end
end
end

@testset "AbstractFields.jl" begin
    @abstractfields struct Foo
        x::Int
        y
    end

    @abstractfields struct Bar <: Foo
        w::String
    end

    @inheritfields struct FooBar <: Bar
        z
    end

    struct BarFoo <: Foo
        x::Int
        # drop y
        a
    end
    
    @testall(Foo, (:x, :y), Core.svec(Int64, Any))
    @testall(Bar, (:x, :y, :w), Core.svec(Int64, Any, String))
    @testall(FooBar, (:x, :y, :w, :z), Core.svec(Int64, Any, String, Any))
    @testall(BarFoo, (:x, :a), Core.svec(Int64, Any))
end

