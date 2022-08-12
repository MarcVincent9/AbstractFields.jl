module AbstractFields

export @abstractfields, @inheritfields, @getters, @setters

import Base: @invoke, fieldnames, fieldname, hasfield, fieldcount, getproperty

using MacroTools


abstract type AbstractStruct end

_abstractfields_dict = Dict{Symbol, Array{Union{Expr, Symbol}}}() # TODO getindex: default=[]


# TODO filter constructors out of fields (look for 'new' or type name)

macro abstractfields(ex)
    @capture(ex, struct T_ fields__ end) || error(
        "@abstractfields takes a struct declaration as argument")
    if @capture(T, B_ <: A_)
        if A in keys(_abstractfields_dict)
            _abstractfields_dict[B] = [_abstractfields_dict[A]; fields]
        else
            _abstractfields_dict[B] = fields
        end
        res = quote
            abstract type $B <: $A end
        end
        esc(res) # evaluate in the macro call environment to find parent type
    else
        _abstractfields_dict[T] = fields
        quote
            abstract type $T <: AbstractStruct end
        end
    end
end

# TODO in capture: (macro struct) | struct
macro inheritfields(ex)
    if @capture(ex, mutable struct B_ <: A_ fields__ end)
        A in keys(_abstractfields_dict) || error(
            "invalid subtyping in definition of $T: 
            parent type $A must be declared with @abstractfields")
        res = quote
            mutable struct $B <: $A
                $(_abstractfields_dict[A]...)
                $(fields...)
            end
        end
    else
        @capture(ex, struct B_ <: A_ fields__ end) || error(
            "@inheritfields takes a (mutable) struct subtype declaration as argument")
        A in keys(_abstractfields_dict) || error(
            "invalid subtyping in definition of $T: 
            parent type $A must be declared with @abstractfields")
        res = quote
            struct $B <: $A
                $(_abstractfields_dict[A]...)
                $(fields...)
            end
        end
    end
    esc(res) # evaluate in the macro call environment to find parent type
end

macro getters(ex)
    T = Core.eval(__module__, ex)::Type # evaluate type name in macro call module
    getters = [:($name(x::$ex) = getfield(x, $(Meta.quot(name)))) for name in fieldnames(T)]
    res = quote
        $(getters...)
        nothing
    end
    esc(res)
end

macro setters(ex)
    T = Core.eval(__module__, ex)::Type
    ismutabletype(T) || error("type must be mutable to accept setters")
    setters = [
        :($(Symbol("set_$(name)!"))(x::$ex, value) = setproperty!(x, $(Meta.quot(name)), value))
        for name in fieldnames(T)]
    res = quote
        $(setters...)
        nothing
    end
    esc(res)
end


getfields(T::Type{<:AbstractStruct}) = _abstractfields_dict[nameof(T)]

getname(field::Symbol) = field
getname(field::Expr) = (@capture(field, name_::T_); name)::Symbol

gettype(field::Symbol) = Any
gettype(field::Expr) = (@capture(field, name_::T_); eval(T))::Type


function fieldnames(T::Type{<:AbstractStruct})
    isabstracttype(T) && return Tuple(map(getname, getfields(T)))
    @invoke fieldnames(T::DataType)
end

function fieldname(T::Type{<:AbstractStruct}, i::Integer)
    isabstracttype(T) && return getname(getfields(T)[i])::Symbol
    @invoke fieldname(T::DataType, i::Integer)
end

function hasfield(T::Type{<:AbstractStruct}, name::Symbol)
    isabstracttype(T) && return name in map(getname, getfields(T))
    @invoke hasfield(T::DataType, name::Symbol)
end

function fieldcount(T::Type{<:AbstractStruct})
    isabstracttype(T) && return length(getfields(T))
    @invoke fieldcount(T::DataType)
end

function getproperty(value::Type{<:AbstractStruct}, name::Symbol)
    if name === :types && isabstracttype(value)
        Core.svec(map(gettype, getfields(value))...)
    else
        @invoke getproperty(value::DataType, name::Symbol)
    end
end

end

# TODO @concrete mutable struct A
#   x::Getter{Int} = 1
#   y::Setter # only if mutable
#   z = 3
#   v::String
#end

# TODO parametric types? if not possible:
# macro abstractfields(ex)
#     @capture(ex, struct T_Symbol fields__ end)
# ...
# should be possible with postwalk!

