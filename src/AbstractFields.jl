module AbstractFields

export @abstractfields, @inheritfields

import Base: fieldnames, fieldname, hasfield, fieldcount, getproperty

using MacroTools


abstract type AbstractStruct end

_abstractfields_dict = Dict{Symbol, Array{Union{Expr, Symbol}}}()


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

macro inheritfields(ex)
    @capture(ex, struct B_ <: A_ fields__ end) || error(
        "@inheritfields takes a struct subtype declaration as argument")
    A in keys(_abstractfields_dict) || error(
        "invalid subtyping in definition of $T: 
        parent type $A must be declared with @abstractfields")
    res = quote
        struct $B <: $A
            $(_abstractfields_dict[A]...)
            $(fields...)
        end
    end
    esc(res) # evaluate in the macro call environment to find parent type
end

macro fieldgetters(ex)
    @capture(ex, struct T_ fields__ end) || error(
        "@fieldgetters takes a struct declaration as argument")
    T = @capture(T, A_ <: _) ? A : T
    functions = [:($f(x::$T) = getfield(x, $(Meta.quot(f)))) for f in fields]
    res = quote
        $ex
        $(functions...)
        nothing # don't show last method in REPL
    end
    esc(res) # declare methods in the macro call scope
end


macro invoke(ex)
    @capture(ex, f_(args__)) || error(
        "@invoke takes a function call as argument")
    types = map(x -> @capture(x, _::T_) ? T : :Any, args)
    res = quote
        invoke($f, Tuple{$(types...)}, $(args...))
    end
    esc(res)
end

getfields(T::Type{<:AbstractStruct}) = _abstractfields_dict[nameof(T)]

getname(field::Symbol) = field
getname(field::Expr) = (@capture(field, name_::T_); name)::Symbol

gettype(field::Symbol) = Any
gettype(field::Expr) = (@capture(field, name_::T_); eval(T))::Type


function fieldnames(T::Type{<:AbstractStruct})
    if isabstracttype(T)
        Tuple(map(getname, getfields(T)))
    else
        @invoke fieldnames(T::DataType)
    end
end

function fieldname(T::Type{<:AbstractStruct}, i::Integer)
    if isabstracttype(T)
        getname(getfields(T)[i])::Symbol
    else
        @invoke fieldname(T::DataType, i::Integer)
    end
end

function hasfield(T::Type{<:AbstractStruct}, name::Symbol)
    if isabstracttype(T)
        name in map(getname, getfields(T))
    else
        @invoke hasfield(T::DataType, name::Symbol)
    end
end

function fieldcount(T::Type{<:AbstractStruct})
    if isabstracttype(T)
        length(getfields(T))
    else
        @invoke fieldcount(T::DataType)
    end
end

function getproperty(value::Type{<:AbstractStruct}, name::Symbol)
    if name === :types && isabstracttype(value)
        Core.svec(map(gettype, getfields(value))...)
    else
        @invoke getproperty(value::DataType, name::Symbol)
    end
end

end

# TODO account for mutable struct

# TODO parametric types? if not possible:
# macro abstractfields(ex)
#     @capture(ex, struct T_Symbol fields__ end)
# ...
# should be possible with postwalk!

