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
    @testall(Foo, (:x, :y), Core.svec(Int64, Any))

    @abstractfields struct Bar <: Foo
        w::String
    end
    @testall(Bar, (:x, :y, :w), Core.svec(Int64, Any, String))

    @inheritfields struct FooBar <: Bar
        z
    end
    @testall(FooBar, (:x, :y, :w, :z), Core.svec(Int64, Any, String, Any))

    struct BarFoo <: Foo
        x::Int
        # drop y
        a
    end
    @testall(BarFoo, (:x, :a), Core.svec(Int64, Any))
    
    # TODO
    #@inheritfields struct BarFoo2 <: Foo
    #    x::Int
    #    !y # drop y
    #    a
    #end
    #@testall(BarFoo2, (:x, :a), Core.svec(Int64, Any))
    
    abstract type ProtoFoo <: AbstractFields.AbstractStruct end
    #@abstractfields struct ProtoFoo end # equivalent
    
    @abstractfields struct FooFoo <: ProtoFoo
        x::Int # = 1
        y
    end
    @testall(FooFoo, (:x, :y), Core.svec(Int64, Any))
    
    #@kwdef # TODO
    @inheritfields struct BarBar <: FooFoo
        z::Float64 # = 2.0
    end
    @testall(BarBar, (:x, :y, :z), Core.svec(Int64, Any, Float64))
    
end

