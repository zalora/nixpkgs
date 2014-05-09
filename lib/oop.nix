# Object Oriented Programming library for Nix
# By Russell O'Connor in collaboration with David Cunningham.
#
# This library provides support for object oriented programming in Nix.
# The library uses the following concepts.
#
# A *class* is an open recursive set.  An open recursive set is a function from
# self to a set.  For example:
#
#     self : { x = 4; y = self.x + 1 }
#
# Technically an open recursive set is not recursive at all, however the function
# is intended to be used to form a fixed point where self will be the resulting
# set.
#
# An *object* is a value which is the fixed point of a class.  For example:
#
#    let class = self : { x = 4; y = self.x + 1; };
#        object = class object; in
#    object
#
# The value of this object is '{ x = 4; y = 5; }'.  The 'new' function in this
# library takes a class and returns an object.
#
#     new (self : { x = 4; y = self. x + 1; });
#
# The 'new' function also adds an attribute called 'nixClass' that returns the
# class that was originally used to define the object.
#
# The attributes of an object are sometimes called *methods*.
#
# Classes can be extended using the 'extend' function in this library.
# the extend function takes a class and extension, and returns a new class.
# An *extension* is a function from self and super to a set containing method
# overrides.  The super argument provides access to methods prior to being
# overloaded.  For example:
#
#    let class = self : { x = 4; y = self.x + 1; };
#        subclass = extend class (self : super : { x = 5; y = super.y * self.x; });
#    in new subclass
#
# denotes '{ x = 5; y = 30; nixClass = <LAMBDA>; }'.  30 equals (5 + 1) * 5).
#
# An extension can also omit the 'super' argument.
#
#    let class = self : { x = 4; y = self.x + 1; };
#        subclass = extend class (self : { y = self.x + 5; });
#    in new subclass
#
# denotes '{ x = 4; y = 9; nixClass = <LAMBDA>; }'.
#
# An extension can also omit both the 'self' and 'super' arguments.
#
#    let class = self : { x = 4; y = self.x + 1; };
#        subclass = extend class { x = 3; };
#    in new subclass
#
# denotes '{ x = 3; y = 4; nixClass = <LAMBDA>; }'.
#
# The 'newExtend' function is a composition of new and extend.  It takes a
# class and and extension and returns an object which is an instance of the
# class extended by the extension.

rec {
  new = class :
    let instance = class instance // { nixClass = class; }; in instance;

  extend = class : extension : self :
    let super = class self; in super //
     (if builtins.isFunction extension
      then let extensionSelf = extension self; in
           if builtins.isFunction extensionSelf
           then extensionSelf super
           else extensionSelf
      else extension
     );

  newExtend = class : extension : new (extend class extension);
}
