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

abstract type ProtoFoo <: AbstractFields.AbstractStruct end
#@abstractfields struct ProtoFoo end # equivalent

@abstractfields struct FooFoo <: ProtoFoo
    x::Int # = 1
    y
end

#@kwdef # TODO
@inheritfields mutable struct BarBar <: FooFoo
    z::Float64 # = 2.0
end

@getters(BarFoo)
@setters(BarBar)


@testset "AbstractFields.jl" begin
    @testall(Foo, (:x, :y), Core.svec(Int64, Any))
    @testall(Bar, (:x, :y, :w), Core.svec(Int64, Any, String))
    @testall(FooBar, (:x, :y, :w, :z), Core.svec(Int64, Any, String, Any))
    @testall(BarFoo, (:x, :a), Core.svec(Int64, Any))
    
    # TODO
    #@inheritfields struct BarFoo2 <: Foo
    #    x::Int
    #    !y # drop y
    #    a
    #end
    #@testall(BarFoo2, (:x, :a), Core.svec(Int64, Any))
    
    @testall(FooFoo, (:x, :y), Core.svec(Int64, Any))
    @testall(BarBar, (:x, :y, :z), Core.svec(Int64, Any, Float64))
    
    @testset "getters" begin
    	bf = BarFoo(1, 2)
    	@test x(bf) == 1
    	@test a(bf) == 2
    end
    
    @testset "setters" begin
    	bb = BarBar(1, 2, 3)
    	set_x!(bb, 10)
    	set_z!(bb, 20)
    	@test bb.x == 10
    	@test bb.z == 20
    end
    
end

