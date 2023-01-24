#TL:1:Gnome::Gtk4::Widget:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::Gtk4::Widget

The base class for all widgets.


=comment ![](images/X.png)


=head1 Description

* `GtkWidget` is the base class all widgets in GTK derive from. It manages the
widget lifecycle, layout, states and style.

=head3 Height-for-width Geometry Management

GTK uses a height-for-width (and width-for-height) geometry management
system. Height-for-width means that a widget can change how much
vertical space it needs, depending on the amount of horizontal space
that it is given (and similar for width-for-height). The most common
example is a label that reflows to fill up the available width, wraps
to fewer lines, and therefore needs less height.

Height-for-width geometry management is implemented in GTK by way
of two virtual methods:

=item C<.get-request-mode()>

=item C<.measure()>

There are some important things to keep in mind when implementing
height-for-width and when using it in widget implementations.

If you implement a direct `GtkWidget` subclass that supports
height-for-width or width-for-height geometry management for itself
or its child widgets, the C<.get-request-mode()> virtual
function must be implemented as well and return the widget's preferred
request mode. The default implementation of this virtual function
returns %GTK_SIZE_REQUEST_CONSTANT_SIZE, which means that the widget will
only ever get -1 passed as the for_size value to its
C<.measure()> implementation.

The geometry management system will query a widget hierarchy in
only one orientation at a time. When widgets are initially queried
for their minimum sizes it is generally done in two initial passes
in the [enum@Gtk.SizeRequestMode] chosen by the toplevel.

For example, when queried in the normal %GTK_SIZE_REQUEST_HEIGHT_FOR_WIDTH mode:

First, the default minimum and natural width for each widget
in the interface will be computed using [id@gtk_widget_measure] with an
orientation of %GTK_ORIENTATION_HORIZONTAL and a for_size of -1.
Because the preferred widths for each widget depend on the preferred
widths of their children, this information propagates up the hierarchy,
and finally a minimum and natural width is determined for the entire
toplevel. Next, the toplevel will use the minimum width to query for the
minimum height contextual to that width using [id@gtk_widget_measure] with an
orientation of %GTK_ORIENTATION_VERTICAL and a for_size of the just computed
width. This will also be a highly recursive operation. The minimum height
for the minimum width is normally used to set the minimum size constraint
on the toplevel.

After the toplevel window has initially requested its size in both
dimensions it can go on to allocate itself a reasonable size (or a size
previously specified with C<Gnome::Gtk4::Window.set-default-size()>). During the
recursive allocation process it’s important to note that request cycles
will be recursively executed while widgets allocate their children.
Each widget, once allocated a size, will go on to first share the
space in one orientation among its children and then request each child's
height for its target allocated width or its width for allocated height,
depending. In this way a `GtkWidget` will typically be requested its size
a number of times before actually being allocated a size. The size a
widget is finally allocated can of course differ from the size it has
requested. For this reason, `GtkWidget` caches a  small number of results
to avoid re-querying for the same sizes in one allocation cycle.

If a widget does move content around to intelligently use up the
allocated size then it must support the request in both
`GtkSizeRequestMode`s even if the widget in question only
trades sizes in a single orientation.

For instance, a B<Gnome::Gtk4::Label> that does height-for-width word wrapping
will not expect to have C<.measure()> with an orientation of
%GTK_ORIENTATION_VERTICAL called because that call is specific to a
width-for-height request. In this case the label must return the height
required for its own minimum possible width. By following this rule any
widget that handles height-for-width or width-for-height requests will
always be allocated at least enough space to fit its own content.

Here are some examples of how a %GTK_SIZE_REQUEST_HEIGHT_FOR_WIDTH widget
generally deals with width-for-height requests:

```c
static void
foo_widget_measure (GtkWidget widget,
GtkOrientation  orientation,
int             for_size,
int minimum_size,
int natural_size,
int minimum_baseline,
int natural_baseline)
{
if (orientation == GTK_ORIENTATION_HORIZONTAL)
{
// Calculate minimum and natural width
}
else // VERTICAL
{
if (i_am_in_height_for_width_mode)
{
int min_width, dummy;

// First, get the minimum width of our widget
GTK_WIDGET_GET_CLASS (widget)->measure (widget, GTK_ORIENTATION_HORIZONTAL, -1,
&min_width, &dummy, &dummy, &dummy);

// Now use the minimum width to retrieve the minimum and natural height to display
// that width.
GTK_WIDGET_GET_CLASS (widget)->measure (widget, GTK_ORIENTATION_VERTICAL, min_width,
minimum_size, natural_size, &dummy, &dummy);
}
else
{
// ... some widgets do both.
}
}
}
```

Often a widget needs to get its own request during size request or
allocation. For example, when computing height it may need to also
compute width. Or when deciding how to use an allocation, the widget
may need to know its natural size. In these cases, the widget should
be careful to call its virtual methods directly, like in the code
example above.

It will not work to use the wrapper function C<.measure()>
inside your own C<.size-allocate()> implementation.
These return a request adjusted by B<Gnome::Gtk4::SizeGroup>, the widget's
align and expand flags, as well as its CSS style.

If a widget used the wrappers inside its virtual method implementations,
then the adjustments (such as widget margins) would be applied
twice. GTK therefore does not allow this and will warn if you try
to do it.

Of course if you are getting the size request for another widget, such
as a child widget, you must use [id@gtk_widget_measure]; otherwise, you
would not properly consider widget margins, B<Gnome::Gtk4::SizeGroup>, and
so forth.

GTK also supports baseline vertical alignment of widgets. This
means that widgets are positioned such that the typographical baseline of
widgets in the same row are aligned. This happens if a widget supports
baselines, has a vertical alignment of %GTK_ALIGN_BASELINE, and is inside
a widget that supports baselines and has a natural “row” that it aligns to
the baseline, or a baseline assigned to it by the grandparent.

Baseline alignment support for a widget is also done by the
C<.measure()> virtual function. It allows you to report
both a minimum and natural size.

If a widget ends up baseline aligned it will be allocated all the space in
the parent as if it was %GTK_ALIGN_FILL, but the selected baseline can be
found via [id@gtk_widget_get_allocated_baseline]. If the baseline has a
value other than -1 you need to align the widget such that the baseline
appears at the position.

=head3 GtkWidget as GtkBuildable

The `GtkWidget` implementation of the `GtkBuildable` interface
supports various custom elements to specify additional aspects of widgets
that are not directly expressed as properties.

If the widget uses a B<Gnome::Gtk4::LayoutManager>, `GtkWidget` supports
a custom `<layout>` element, used to define layout properties:

```xml
<object class="GtkGrid" id="my_grid">
<child>
<object class="GtkLabel" id="label1">
<property name="label">Description</property>
<layout>
<property name="column">0</property>
<property name="row">0</property>
<property name="row-span">1</property>
<property name="column-span">1</property>
</layout>
</object>
</child>
<child>
<object class="GtkEntry" id="description_entry">
<layout>
<property name="column">1</property>
<property name="row">0</property>
<property name="row-span">1</property>
<property name="column-span">1</property>
</layout>
</object>
</child>
</object>
```

`GtkWidget` allows style information such as style classes to
be associated with widgets, using the custom `<style>` element:

```xml
<object class="GtkButton" id="button1">
<style>
<class name="my-special-button-class"/>
<class name="dark-button"/>
</style>
</object>
```

`GtkWidget` allows defining accessibility information, such as properties,
relations, and states, using the custom `<accessibility>` element:

```xml
<object class="GtkButton" id="button1">
<accessibility>
<property name="label">Download</property>
<relation name="labelled-by">label1</relation>
</accessibility>
</object>
```

=head3 Building composite widgets from template XML

`GtkWidget `exposes some facilities to automate the procedure
of creating composite widgets using "templates".

To create composite widgets with `GtkBuilder` XML, one must associate
the interface description with the widget class at class initialization
time using C<Gnome::Gtk4::WidgetClass.set-template()>.

The interface description semantics expected in composite template descriptions
is slightly different from regular B<Gnome::Gtk4::Builder> XML.

Unlike regular interface descriptions, C<Gnome::Gtk4::WidgetClass.set-template()> will
expect a `<template>` tag as a direct child of the toplevel `<interface>`
tag. The `<template>` tag must specify the “class” attribute which must be
the type name of the widget. Optionally, the “parent” attribute may be
specified to specify the direct parent type of the widget type, this is
ignored by `GtkBuilder` but required for UI design tools like
[Glade](https://glade.gnome.org/) to introspect what kind of properties and
internal children exist for a given type when the actual type does not exist.

The XML which is contained inside the `<template>` tag behaves as if it were
added to the `<object>` tag defining the widget itself. You may set properties
on a widget by inserting `<property>` tags into the `<template>` tag, and also
add `<child>` tags to add children and extend a widget in the normal way you
would with `<object>` tags.

Additionally, `<object>` tags can also be added before and after the initial
`<template>` tag in the normal way, allowing one to define auxiliary objects
which might be referenced by other widgets declared as children of the
`<template>` tag.

=begin comment
An example of a template definition:

```xml
<interface>
<template class="FooWidget" parent="GtkBox">
<property name="orientation">horizontal</property>
<property name="spacing">4</property>
<child>
<object class="GtkButton" id="hello_button">
<property name="label">Hello World</property>
<signal name="clicked" handler="hello_button_clicked" object="FooWidget" swapped="yes"/>
</object>
</child>
<child>
<object class="GtkButton" id="goodbye_button">
<property name="label">Goodbye World</property>
</object>
</child>
</template>
</interface>
```

Typically, you'll place the template fragment into a file that is
bundled with your project, using `GResource`. In order to load the
template, you need to call C<Gnome::Gtk4::WidgetClass.set-template-from-resource()>
from the class initialization of your `GtkWidget` type:

```c
static void
foo_widget_class_init (FooWidgetClass klass)
{
// ...

gtk_widget_class_set_template_from_resource (GTK_WIDGET_CLASS (klass),
"/com/example/ui/foowidget.ui");
}
```

You will also need to call C<.init-template()> from the
instance initialization function:

```c
static void
foo_widget_init (FooWidget self)
{
// ...
gtk_widget_init_template (GTK_WIDGET (self));
}
```

You can access widgets defined in the template using the
[id@gtk_widget_get_template_child] function, but you will typically declare
a pointer in the instance private data structure of your type using the same
name as the widget in the template definition, and call
C<Gnome::Gtk4::WidgetClass.bind-template-child-full()> (or one of its wrapper macros
[func@Gtk.widget_class_bind_template_child] and [func@Gtk.widget_class_bind_template_child_private])
with that name, e.g.

```c
typedef struct {
GtkWidget hello_button;
GtkWidget goodbye_button;
} FooWidgetPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (FooWidget, foo_widget, GTK_TYPE_BOX)

static void
foo_widget_class_init (FooWidgetClass klass)
{
// ...
gtk_widget_class_set_template_from_resource (GTK_WIDGET_CLASS (klass),
"/com/example/ui/foowidget.ui");
gtk_widget_class_bind_template_child_private (GTK_WIDGET_CLASS (klass),
FooWidget, hello_button);
gtk_widget_class_bind_template_child_private (GTK_WIDGET_CLASS (klass),
FooWidget, goodbye_button);
}

static void
foo_widget_init (FooWidget widget)
{

}
```

You can also use C<Gnome::Gtk4::WidgetClass.bind-template-callback-full()> (or
is wrapper macro [func@Gtk.widget_class_bind_template_callback]) to connect
a signal callback defined in the template with a function visible in the
scope of the class, e.g.

```c
// the signal handler has the instance and user data swapped
// because of the swapped="yes" attribute in the template XML
static void
hello_button_clicked (FooWidget self,
GtkButton button)
{
g_print ("Hello, world!\n");
}

static void
foo_widget_class_init (FooWidgetClass klass)
{
// ...
gtk_widget_class_set_template_from_resource (GTK_WIDGET_CLASS (klass),
"/com/example/ui/foowidget.ui");
gtk_widget_class_bind_template_callback (GTK_WIDGET_CLASS (klass), hello_button_clicked);
}
```
=end comment

=head1 Synopsis
=head2 Declaration

  unit class Gnome::Gtk4::Widget;
  also is Gnome::GObject::InitiallyUnowned;


=comment head2 Uml Diagram

=comment ![](plantuml/Widget.svg)


=comment head2 Example

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

#use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

use Gnome::GObject::InitiallyUnowned;

use Gnome::Gtk4::Enums;

#-------------------------------------------------------------------------------
unit class Gnome::Gtk4::Widget:auth<github:MARTIMM>;
also is Gnome::GObject::InitiallyUnowned;


#-------------------------------------------------------------------------------
=begin pod
=head1 Types
=end pod
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GtkRequisition

A `GtkRequisition` represents the desired size of a widget. See
[GtkWidget’s geometry management section](class.Widget.html height-for-width-geometry-management) for
more information.


=item C<Int()> $.width: the widget’s desired width
=item C<Int()> $.height: the widget’s desired height


=end pod

#TT:0:N-GtkRequisition:
class N-GtkRequisition is export is repr('CStruct') {
  has int $.width;
  has int $.height;
}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GtkTickCallback

Callback type for adding a function to update animations. See C<add_tick_callback()>.

Returns: C<G_SOURCE_CONTINUE> if the tick callback should continue to be called,
C<G_SOURCE_REMOVE> if the tick callback should be removed.


=item ___widget: the widget
=item ___frame_clock: the frame clock for the widget (same as calling C<get_frame_clock()>)
=item ___user_data: user data passed to C<add_tick_callback()>.


=end pod

#TT:0:N-GtkTickCallback:
class N-GtkTickCallback is export is repr('CStruct') {
  has GInitiallyUnowned $.parent_instance;
  has GtkWidgetPrivate $.priv;
}
}}

#-------------------------------------------------------------------------------
my Bool $signals-added = False;
#-------------------------------------------------------------------------------

=begin pod
=head1 Methods
=head2 new

=head3 default, no options

Create a new Widget object.

  multi method new ( )


=head3 :native-object

Create a Widget object using a native object from elsewhere. See also B<Gnome::N::TopLevelClassSupport>.

  multi method new ( N-GObject :$native-object! )


=head3 :build-id

Create a Widget object using a native object returned from a builder. See also B<Gnome::GObject::Object>.

  multi method new ( Str :$build-id! )

=end pod

#TM:0:new():inheriting
#TM:1:new():
#TM:4:new(:native-object):Gnome::N::TopLevelClassSupport
#TM:4:new(:build-id):Gnome::GObject::Object

submethod BUILD ( *%options ) {

  # add signal info in the form of w*<signal-name>.
  unless $signals-added {
    $signals-added = self.add-signal-types( $?CLASS.^name,
      :w4<query-tooltip>, :w0<destroy show hide map unmap realize unrealize>, :w1<state-flags-changed direction-changed mnemonic-activate move-focus keynav-failed>,
    );

    # signals from interfaces
    #_add_..._signal_types($?CLASS.^name);
  }


  # prevent creating wrong native-objects
  if self.^name eq 'Gnome::Gtk4::Widget' {

    # check if native object is set by a parent class
    if self.is-valid { }

    # check if common options are handled by some parent
    elsif %options<native-object>:exists { }
    elsif %options<build-id>:exists { }

    # process all other options
    else {
      my $no;
      if ? %options<___x___> {
        #$no = %options<___x___>;
        #$no .= _get-native-object-no-reffing unless $no ~~ N-GObject;
        #$no = _gtk_widget_new___x___($no);
      }

      #`{{ use this when the module is not made inheritable
      # check if there are unknown options
      elsif %options.elems {
        die X::Gnome.new(
          :message(
            'Unsupported, undefined, incomplete or wrongly typed options for ' ~
            self.^name ~ ': ' ~ %options.keys.join(', ')
          )
        );
      }
      }}

      #`{{ when there are no defaults use this
      # check if there are any options
      elsif %options.elems == 0 {
        die X::Gnome.new(:message('No options specified ' ~ self.^name));
      }
      }}

      #`{{ when there are defaults use this instead
      # create default object
      else {
        $no = _gtk_widget_new();
      }
      }}

      self.set-native-object($no);
    }

    # only after creating the native-object, the gtype is known
    self._set-class-info('GtkWidget');
  }
}


#-------------------------------------------------------------------------------
#TM:0:action-set-enabled:
=begin pod
=head2 action-set-enabled

Enable or disable an action installed with C<class_install_action()>.

  method action-set-enabled ( Str $action_name, Bool $enabled )

=item $action_name; action name, such as "clipboard.paste"
=item $enabled; whether the action is now enabled
=end pod

method action-set-enabled ( Str $action_name, Bool $enabled ) {
  gtk_widget_action_set_enabled( self._f('GtkWidget'), $action_name, $enabled);
}

sub gtk_widget_action_set_enabled (
  N-GObject $widget, gchar-ptr $action_name, gboolean $enabled
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:activate:
=begin pod
=head2 activate

For widgets that can be “activated” (buttons, menu items, etc.), this function activates them.

The activation will emit the signal set using [methodI<Gtk>.WidgetClass.set_activate_signal] during class initialization.

Activation is what happens when you press <kbd>Enter</kbd> on a widget during key navigation.

If you wish to handle the activation keybinding yourself, it is recommended to use [methodI<Gtk>.WidgetClass.add_shortcut] with an action created with [ctorI<Gtk>.SignalAction.new].

If I<widget> isn't activatable, the function returns C<False>.

Returns: C<True> if the widget was activatable

  method activate ( --> Bool )

=end pod

method activate ( --> Bool ) {
  gtk_widget_activate( self._f('GtkWidget')).Bool
}

sub gtk_widget_activate (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:activate-action:
=begin pod
=head2 activate-action

Looks up the action in the action groups associated with I<widget> and its ancestors, and activates it.

This is a wrapper around [methodI<Gtk>.Widget.activate_action_variant] that constructs the I<args> variant according to I<format_string>.

Returns: C<True> if the action was activated, C<False> if the action does not exist

  method activate-action ( Str $name, Str $format_string --> Bool )

=item $name; the name of the action to activate
=item $format_string; GVariant format string for arguments or C<undefined> for no arguments @...: arguments, as given by format string
=end pod

method activate-action ( Str $name, Str $format_string --> Bool ) {
  gtk_widget_activate_action( self._f('GtkWidget'), $name, $format_string).Bool
}

sub gtk_widget_activate_action (
  N-GObject $widget, gchar-ptr $name, gchar-ptr $format_string, Any $any = Any --> gboolean
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:activate-action-variant:
=begin pod
=head2 activate-action-variant

Looks up the action in the action groups associated with I<widget> and its ancestors, and activates it.

If the action is in an action group added with [methodI<Gtk>.Widget.insert_action_group], the I<name> is expected to be prefixed with the prefix that was used when the group was inserted.

The arguments must match the actions expected parameter type, as returned by `C<g_action_get_parameter_type()>`.

Returns: C<True> if the action was activated, C<False> if the action does not exist.

  method activate-action-variant ( Str $name, N-GObject() $args --> Bool )

=item $name; the name of the action to activate
=item $args; parameters to use
=end pod

method activate-action-variant ( Str $name, N-GObject() $args --> Bool ) {
  gtk_widget_activate_action_variant( self._f('GtkWidget'), $name, $args).Bool
}

sub gtk_widget_activate_action_variant (
  N-GObject $widget, gchar-ptr $name, N-GObject $args --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:activate-default:
=begin pod
=head2 activate-default

Activates the `default.activate` action from I<widget>.

  method activate-default ( )

=end pod

method activate-default ( ) {
  gtk_widget_activate_default( self._f('GtkWidget'));
}

sub gtk_widget_activate_default (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:add-controller:
=begin pod
=head2 add-controller

Adds I<controller> to I<widget> so that it will receive events.

You will usually want to call this function right after creating any kind of [classI<Gtk>.EventController].

  method add-controller ( N-GObject() $controller )

=item $controller; a `GtkEventController` that hasn't been added to a widget yet
=end pod

method add-controller ( N-GObject() $controller ) {
  gtk_widget_add_controller( self._f('GtkWidget'), $controller);
}

sub gtk_widget_add_controller (
  N-GObject $widget, N-GObject $controller
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:add-css-class:
=begin pod
=head2 add-css-class

Adds a style class to I<widget>.

After calling this function, the widgets style will match for I<css_class>, according to CSS matching rules.

Use [methodI<Gtk>.Widget.remove_css_class] to remove the style again.

  method add-css-class ( Str $css_class )

=item $css_class; The style class to add to I<widget>, without the leading '.' used for notation of style classes
=end pod

method add-css-class ( Str $css_class ) {
  gtk_widget_add_css_class( self._f('GtkWidget'), $css_class);
}

sub gtk_widget_add_css_class (
  N-GObject $widget, gchar-ptr $css_class
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:add-mnemonic-label:
=begin pod
=head2 add-mnemonic-label

Adds a widget to the list of mnemonic labels for this widget.

See [methodI<Gtk>.Widget.list_mnemonic_labels]. Note the list of mnemonic labels for the widget is cleared when the widget is destroyed, so the caller must make sure to update its internal state at this point as well.

  method add-mnemonic-label ( N-GObject() $label )

=item $label; a `GtkWidget` that acts as a mnemonic label for I<widget>
=end pod

method add-mnemonic-label ( N-GObject() $label ) {
  gtk_widget_add_mnemonic_label( self._f('GtkWidget'), $label);
}

sub gtk_widget_add_mnemonic_label (
  N-GObject $widget, N-GObject $label
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:add-tick-callback:
=begin pod
=head2 add-tick-callback

Queues an animation frame update and adds a callback to be called before each frame.

Until the tick callback is removed, it will be called frequently (usually at the frame rate of the output device or as quickly as the application can be repainted, whichever is slower). For this reason, is most suitable for handling graphics that change every frame or every few frames. The tick callback does not automatically imply a relayout or repaint. If you want a repaint or relayout, and aren’t changing widget properties that would trigger that (for example, changing the text of a `GtkLabel`), then you will have to call [methodI<Gtk>.Widget.queue_resize] or [methodI<Gtk>.Widget.queue_draw] yourself.

[methodI<Gdk>.FrameClock.get_frame_time] should generally be used for timing continuous animations and [methodI<Gdk>.FrameTimings.get_predicted_presentation_time] if you are trying to display isolated frames at particular times.

This is a more convenient alternative to connecting directly to the [signalI<Gdk>.FrameClock::update] signal of `GdkFrameClock`, since you don't have to worry about when a `GdkFrameClock` is assigned to a widget.

Returns: an id for the connection of this callback. Remove the callback by passing the id returned from this function to [methodI<Gtk>.Widget.remove_tick_callback]

  method add-tick-callback ( GtkTickCallback $callback, Pointer $user_data, GDestroyNotify $notify --> UInt )

=item $callback; function to call for updating animations
=item $user_data; (closure): data to pass to I<callback>
=item $notify; function to call to free I<user_data> when the callback is removed.
=end pod

method add-tick-callback ( GtkTickCallback $callback, Pointer $user_data, GDestroyNotify $notify --> UInt ) {
  gtk_widget_add_tick_callback( self._f('GtkWidget'), $callback, $user_data, $notify)
}

sub gtk_widget_add_tick_callback (
  N-GObject $widget, GtkTickCallback $callback, gpointer $user_data, GDestroyNotify $notify --> guint
) is native(&gtk4-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:allocate:
=begin pod
=head2 allocate

This function is only used by `GtkWidget` subclasses, to assign a size, position and (optionally) baseline to their child widgets.

In this function, the allocation and baseline may be adjusted. The given allocation will be forced to be bigger than the widget's minimum size, as well as at least 0×0 in size.

For a version that does not take a transform, see [methodI<Gtk>.Widget.size_allocate].

  method allocate ( Int() $width, Int() $height, Int() $baseline, GskTransform $transform )

=item $width; New width of I<widget>
=item $height; New height of I<widget>
=item $baseline; New baseline of I<widget>, or -1
=item $transform; Transformation to be applied to I<widget>
=end pod

method allocate ( Int() $width, Int() $height, Int() $baseline, GskTransform $transform ) {
  gtk_widget_allocate( self._f('GtkWidget'), $width, $height, $baseline, $transform);
}

sub gtk_widget_allocate (
  N-GObject $widget, int $width, int $height, int $baseline, GskTransform $transform
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:child-focus:
=begin pod
=head2 child-focus

Called by widgets as the user moves around the window using keyboard shortcuts.

The I<direction> argument indicates what kind of motion is taking place (up, down, left, right, tab forward, tab backward).

This function calls the [vfuncI<Gtk>.Widget.focus] virtual function; widgets can override the virtual function in order to implement appropriate focus behavior.

The default `C<focus()>` virtual function for a widget should return `TRUE` if moving in I<direction> left the focus on a focusable location inside that widget, and `FALSE` if moving in I<direction> moved the focus outside the widget. When returning `TRUE`, widgets normallycall [methodI<Gtk>.Widget.grab_focus] to place the focus accordingly; when returning `FALSE`, they don’t modify the current focus location.

This function is used by custom widget implementations; if you're writing an app, you’d use [methodI<Gtk>.Widget.grab_focus] to move the focus to a particular widget.

Returns: C<True> if focus ended up inside I<widget>

  method child-focus ( GtkDirectionType $direction --> Bool )

=item $direction; direction of focus movement
=end pod

method child-focus ( GtkDirectionType $direction --> Bool ) {
  gtk_widget_child_focus( self._f('GtkWidget'), $direction).Bool
}

sub gtk_widget_child_focus (
  N-GObject $widget, GEnum $direction --> gboolean
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:class-add-binding:
=begin pod
=head2 class-add-binding

Creates a new shortcut for I<widget_class> that calls the given I<callback> with arguments read according to I<format_string>.

The arguments and format string must be provided in the same way as with C<g_variant_new()>.

This function is a convenience wrapper around [methodI<Gtk>.WidgetClass.add_shortcut] and must be called during class initialization. It does not provide for user_data, if you need that, you will have to use [methodI<GtkWidgetClass>.add_shortcut] with a custom shortcut.

  method class-add-binding ( GtkWidgetClass $widget_class, UInt $keyval, GdkModifierType $mods, GtkShortcutFunc $callback, Str $format_string )

=item $widget_class; the class to add the binding to
=item $keyval; key value of binding to install
=item $mods; key modifier of binding to install
=item $callback; the callback to call upon activation
=item $format_string; GVariant format string for arguments or C<undefined> for no arguments @...: arguments, as given by format string
=end pod

method class-add-binding ( GtkWidgetClass $widget_class, UInt $keyval, GdkModifierType $mods, GtkShortcutFunc $callback, Str $format_string ) {
  gtk_widget_class_add_binding( self._f('GtkWidget'), $widget_class, $keyval, $mods, $callback, $format_string);
}

sub gtk_widget_class_add_binding (
  GtkWidgetClass $widget_class, guint $keyval, GEnum $mods, GtkShortcutFunc $callback, gchar-ptr $format_string, Any $any = Any
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-add-binding-action:
=begin pod
=head2 class-add-binding-action

Creates a new shortcut for I<widget_class> that activates the given I<action_name> with arguments read according to I<format_string>.

The arguments and format string must be provided in the same way as with C<g_variant_new()>.

This function is a convenience wrapper around [methodI<Gtk>.WidgetClass.add_shortcut] and must be called during class initialization.

  method class-add-binding-action ( GtkWidgetClass $widget_class, UInt $keyval, GdkModifierType $mods, Str $action_name, Str $format_string )

=item $widget_class; the class to add the binding to
=item $keyval; key value of binding to install
=item $mods; key modifier of binding to install
=item $action_name; the action to activate
=item $format_string; GVariant format string for arguments or C<undefined> for no arguments @...: arguments, as given by format string
=end pod

method class-add-binding-action ( GtkWidgetClass $widget_class, UInt $keyval, GdkModifierType $mods, Str $action_name, Str $format_string ) {
  gtk_widget_class_add_binding_action( self._f('GtkWidget'), $widget_class, $keyval, $mods, $action_name, $format_string);
}

sub gtk_widget_class_add_binding_action (
  GtkWidgetClass $widget_class, guint $keyval, GEnum $mods, gchar-ptr $action_name, gchar-ptr $format_string, Any $any = Any
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-add-binding-signal:
=begin pod
=head2 class-add-binding-signal

Creates a new shortcut for I<widget_class> that emits the given action I<signal> with arguments read according to I<format_string>.

The arguments and format string must be provided in the same way as with C<g_variant_new()>.

This function is a convenience wrapper around [methodI<Gtk>.WidgetClass.add_shortcut] and must be called during class initialization.

  method class-add-binding-signal ( GtkWidgetClass $widget_class, UInt $keyval, GdkModifierType $mods, Str $signal, Str $format_string )

=item $widget_class; the class to add the binding to
=item $keyval; key value of binding to install
=item $mods; key modifier of binding to install
=item $signal; the signal to execute
=item $format_string; GVariant format string for arguments or C<undefined> for no arguments @...: arguments, as given by format string
=end pod

method class-add-binding-signal ( GtkWidgetClass $widget_class, UInt $keyval, GdkModifierType $mods, Str $signal, Str $format_string ) {
  gtk_widget_class_add_binding_signal( self._f('GtkWidget'), $widget_class, $keyval, $mods, $signal, $format_string);
}

sub gtk_widget_class_add_binding_signal (
  GtkWidgetClass $widget_class, guint $keyval, GEnum $mods, gchar-ptr $signal, gchar-ptr $format_string, Any $any = Any
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-add-shortcut:
=begin pod
=head2 class-add-shortcut

Installs a shortcut in I<widget_class>.

Every instance created for I<widget_class> or its subclasses will inherit this shortcut and trigger it.

Shortcuts added this way will be triggered in the C<GTK_PHASE_BUBBLE> phase, which means they may also trigger if child widgets have focus.

This function must only be used in class initialization functions otherwise it is not guaranteed that the shortcut will be installed.

  method class-add-shortcut ( GtkWidgetClass $widget_class, GtkShortcut $shortcut )

=item $widget_class; the class to add the shortcut to
=item $shortcut; the `GtkShortcut` to add
=end pod

method class-add-shortcut ( GtkWidgetClass $widget_class, GtkShortcut $shortcut ) {
  gtk_widget_class_add_shortcut( self._f('GtkWidget'), $widget_class, $shortcut);
}

sub gtk_widget_class_add_shortcut (
  GtkWidgetClass $widget_class, GtkShortcut $shortcut
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-bind-template-callback-full:
=begin pod
=head2 class-bind-template-callback-full

Declares a I<callback_symbol> to handle I<callback_name> from the template XML defined for I<widget_type>.

This function is not supported after [methodI<Gtk>.WidgetClass.set_template_scope] has been used on I<widget_class>. See [methodI<Gtk>.BuilderCScope.add_callback_symbol].

Note that this must be called from a composite widget classes class initializer after calling [methodI<Gtk>.WidgetClass.set_template].

  method class-bind-template-callback-full ( GtkWidgetClass $widget_class, Str $callback_name, GCallback $callback_symbol )

=item $widget_class; A `GtkWidgetClass`
=item $callback_name; The name of the callback as expected in the template XML
=item $callback_symbol; (scope async): The callback symbol
=end pod

method class-bind-template-callback-full ( GtkWidgetClass $widget_class, Str $callback_name, GCallback $callback_symbol ) {
  gtk_widget_class_bind_template_callback_full( self._f('GtkWidget'), $widget_class, $callback_name, $callback_symbol);
}

sub gtk_widget_class_bind_template_callback_full (
  GtkWidgetClass $widget_class, gchar-ptr $callback_name, GCallback $callback_symbol
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-bind-template-child-full:
=begin pod
=head2 class-bind-template-child-full

Automatically assign an object declared in the class template XML to be set to a location on a freshly built instance’s private data, or alternatively accessible via [methodI<Gtk>.Widget.get_template_child].

The struct can point either into the public instance, then you should use `G_STRUCT_OFFSET(WidgetType, member)` for I<struct_offset>, or in the private struct, then you should use `G_PRIVATE_OFFSET(WidgetType, member)`.

An explicit strong reference will be held automatically for the duration of your instance’s life cycle, it will be released automatically when `GObjectClass.C<dispose()>` runs on your instance and if a I<struct_offset> that is `!= 0` is specified, then the automatic location in your instance public or private data will be set to C<undefined>. You can however access an automated child pointer the first time your classes `GObjectClass.C<dispose()>` runs, or alternatively in [signalI<Gtk>.Widget::destroy].

If I<internal_child> is specified, [vfuncI<Gtk>.Buildable.get_internal_child] will be automatically implemented by the `GtkWidget` class so there is no need to implement it manually.

The wrapper macros [funcI<Gtk>.widget_class_bind_template_child], [funcI<Gtk>.widget_class_bind_template_child_internal], [funcI<Gtk>.widget_class_bind_template_child_private] and [funcI<Gtk>.widget_class_bind_template_child_internal_private] might be more convenient to use.

Note that this must be called from a composite widget classes class initializer after calling [methodI<Gtk>.WidgetClass.set_template].

  method class-bind-template-child-full ( GtkWidgetClass $widget_class, Str $name, Bool $internal_child, Int() $struct_offset )

=item $widget_class; A `GtkWidgetClass`
=item $name; The “id” of the child defined in the template XML
=item $internal_child; Whether the child should be accessible as an “internal-child” when this class is used in GtkBuilder XML
=item $struct_offset; The structure offset into the composite widget’s instance public or private structure where the automated child pointer should be set, or 0 to not assign the pointer.
=end pod

method class-bind-template-child-full ( GtkWidgetClass $widget_class, Str $name, Bool $internal_child, Int() $struct_offset ) {
  gtk_widget_class_bind_template_child_full( self._f('GtkWidget'), $widget_class, $name, $internal_child, $struct_offset);
}

sub gtk_widget_class_bind_template_child_full (
  GtkWidgetClass $widget_class, gchar-ptr $name, gboolean $internal_child, gssize $struct_offset
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-get-accessible-role:
=begin pod
=head2 class-get-accessible-role

Retrieves the accessible role used by the given `GtkWidget` class.

Different accessible roles have different states, and are rendered differently by assistive technologies.

See also: [methodI<Gtk>.Accessible.get_accessible_role].

Returns: the accessible role for the widget class

  method class-get-accessible-role ( GtkWidgetClass $widget_class --> GtkAccessibleRole )

=item $widget_class; a `GtkWidgetClass`
=end pod

method class-get-accessible-role ( GtkWidgetClass $widget_class --> GtkAccessibleRole ) {
  gtk_widget_class_get_accessible_role( self._f('GtkWidget'), $widget_class)
}

sub gtk_widget_class_get_accessible_role (
  GtkWidgetClass $widget_class --> GtkAccessibleRole
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-get-activate-signal:
=begin pod
=head2 class-get-activate-signal

Retrieves the signal id for the activation signal.

the activation signal is set using [methodI<Gtk>.WidgetClass.set_activate_signal].

Returns: a signal id, or 0 if the widget class does not specify an activation signal

  method class-get-activate-signal ( GtkWidgetClass $widget_class --> UInt )

=item $widget_class; a `GtkWidgetClass`
=end pod

method class-get-activate-signal ( GtkWidgetClass $widget_class --> UInt ) {
  gtk_widget_class_get_activate_signal( self._f('GtkWidget'), $widget_class)
}

sub gtk_widget_class_get_activate_signal (
  GtkWidgetClass $widget_class --> guint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-get-css-name:
=begin pod
=head2 class-get-css-name

Gets the name used by this class for matching in CSS code.

See [methodI<Gtk>.WidgetClass.set_css_name] for details.

Returns: the CSS name of the given class

  method class-get-css-name ( GtkWidgetClass $widget_class --> Str )

=item $widget_class; class to set the name on
=end pod

method class-get-css-name ( GtkWidgetClass $widget_class --> Str ) {
  gtk_widget_class_get_css_name( self._f('GtkWidget'), $widget_class)
}

sub gtk_widget_class_get_css_name (
  GtkWidgetClass $widget_class --> gchar-ptr
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-get-layout-manager-type:
=begin pod
=head2 class-get-layout-manager-type

Retrieves the type of the [classI<Gtk>.LayoutManager] used by widgets of class I<widget_class>.

See also: [methodI<Gtk>.WidgetClass.set_layout_manager_type].

Returns: type of a `GtkLayoutManager` subclass, or C<G_TYPE_INVALID>

  method class-get-layout-manager-type ( GtkWidgetClass $widget_class --> N-GObject )

=item $widget_class; a `GtkWidgetClass`
=end pod

method class-get-layout-manager-type ( GtkWidgetClass $widget_class --> N-GObject ) {
  gtk_widget_class_get_layout_manager_type( self._f('GtkWidget'), $widget_class)
}

sub gtk_widget_class_get_layout_manager_type (
  GtkWidgetClass $widget_class --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-install-action:
=begin pod
=head2 class-install-action

This should be called at class initialization time to specify actions to be added for all instances of this class.

Actions installed by this function are stateless. The only state they have is whether they are enabled or not.

  method class-install-action ( GtkWidgetClass $widget_class, Str $action_name, Str $parameter_type, GtkWidgetActionActivateFunc $activate )

=item $widget_class; a `GtkWidgetClass`
=item $action_name; a prefixed action name, such as "clipboard.paste"
=item $parameter_type; the parameter type
=item $activate; (scope notified): callback to use when the action is activated
=end pod

method class-install-action ( GtkWidgetClass $widget_class, Str $action_name, Str $parameter_type, GtkWidgetActionActivateFunc $activate ) {
  gtk_widget_class_install_action( self._f('GtkWidget'), $widget_class, $action_name, $parameter_type, $activate);
}

sub gtk_widget_class_install_action (
  GtkWidgetClass $widget_class, gchar-ptr $action_name, gchar-ptr $parameter_type, GtkWidgetActionActivateFunc $activate
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-install-property-action:
=begin pod
=head2 class-install-property-action

Installs an action called I<action_name> on I<widget_class> and binds its state to the value of the I<property_name> property.

This function will perform a few santity checks on the property selected via I<property_name>. Namely, the property must exist, must be readable, writable and must not be construct-only. There are also restrictions on the type of the given property, it must be boolean, int, unsigned int, double or string. If any of these conditions are not met, a critical warning will be printed and no action will be added.

The state type of the action matches the property type.

If the property is boolean, the action will have no parameter and toggle the property value. Otherwise, the action will have a parameter of the same type as the property.

  method class-install-property-action ( GtkWidgetClass $widget_class, Str $action_name, Str $property_name )

=item $widget_class; a `GtkWidgetClass`
=item $action_name; name of the action
=item $property_name; name of the property in instances of I<widget_class> or any parent class.
=end pod

method class-install-property-action ( GtkWidgetClass $widget_class, Str $action_name, Str $property_name ) {
  gtk_widget_class_install_property_action( self._f('GtkWidget'), $widget_class, $action_name, $property_name);
}

sub gtk_widget_class_install_property_action (
  GtkWidgetClass $widget_class, gchar-ptr $action_name, gchar-ptr $property_name
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-query-action:
=begin pod
=head2 class-query-action

Returns details about the I<index_>-th action that has been installed for I<widget_class> during class initialization.

See [methodI<Gtk>.WidgetClass.install_action] for details on how to install actions.

Note that this function will also return actions defined by parent classes. You can identify those by looking at I<owner>.

Returns: C<True> if the action was found, C<False> if I<index_> is out of range

  method class-query-action ( GtkWidgetClass $widget_class, UInt $index, N-GObject() $owner, CArray[Str] $action_name, N-GObject() $parameter_type, CArray[Str] $property_name --> Bool )

=item $widget_class; a `GtkWidget` class
=item $index; position of the action to query
=item $owner; return location for the type where the action was defined
=item $action_name; return location for the action name
=item $parameter_type; return location for the parameter type
=item $property_name; return location for the property name
=end pod

method class-query-action ( GtkWidgetClass $widget_class, UInt $index, N-GObject() $owner, CArray[Str] $action_name, N-GObject() $parameter_type, CArray[Str] $property_name --> Bool ) {
  gtk_widget_class_query_action( self._f('GtkWidget'), $widget_class, $index, $owner, $action_name, $parameter_type, $property_name).Bool
}

sub gtk_widget_class_query_action (
  GtkWidgetClass $widget_class, guint $index, N-GObject $owner, gchar-pptr $action_name, N-GObject $parameter_type, gchar-pptr $property_name --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-accessible-role:
=begin pod
=head2 class-set-accessible-role

Sets the accessible role used by the given `GtkWidget` class.

Different accessible roles have different states, and are rendered differently by assistive technologies.

  method class-set-accessible-role ( GtkWidgetClass $widget_class, GtkAccessibleRole $accessible_role )

=item $widget_class; a `GtkWidgetClass`
=item $accessible_role; the `GtkAccessibleRole` used by the I<widget_class>
=end pod

method class-set-accessible-role ( GtkWidgetClass $widget_class, GtkAccessibleRole $accessible_role ) {
  gtk_widget_class_set_accessible_role( self._f('GtkWidget'), $widget_class, $accessible_role);
}

sub gtk_widget_class_set_accessible_role (
  GtkWidgetClass $widget_class, GtkAccessibleRole $accessible_role
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-activate-signal:
=begin pod
=head2 class-set-activate-signal

Sets the `GtkWidgetClass.activate_signal` field with the given I<signal_id>.

The signal will be emitted when calling [methodI<Gtk>.Widget.activate].

The I<signal_id> must have been registered with `C<g_signal_new()>` or C<g_signal_newv()> before calling this function.

  method class-set-activate-signal ( GtkWidgetClass $widget_class, UInt $signal_id )

=item $widget_class; a `GtkWidgetClass`
=item $signal_id; the id for the activate signal
=end pod

method class-set-activate-signal ( GtkWidgetClass $widget_class, UInt $signal_id ) {
  gtk_widget_class_set_activate_signal( self._f('GtkWidget'), $widget_class, $signal_id);
}

sub gtk_widget_class_set_activate_signal (
  GtkWidgetClass $widget_class, guint $signal_id
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-activate-signal-from-name:
=begin pod
=head2 class-set-activate-signal-from-name

Sets the `GtkWidgetClass.activate_signal` field with the signal id for the given I<signal_name>.

The signal will be emitted when calling [methodI<Gtk>.Widget.activate].

The I<signal_name> of I<widget_type> must have been registered with C<g_signal_new()> or C<g_signal_newv()> before calling this function.

  method class-set-activate-signal-from-name ( GtkWidgetClass $widget_class, Str $signal_name )

=item $widget_class; a `GtkWidgetClass`
=item $signal_name; the name of the activate signal of I<widget_type>
=end pod

method class-set-activate-signal-from-name ( GtkWidgetClass $widget_class, Str $signal_name ) {
  gtk_widget_class_set_activate_signal_from_name( self._f('GtkWidget'), $widget_class, $signal_name);
}

sub gtk_widget_class_set_activate_signal_from_name (
  GtkWidgetClass $widget_class, gchar-ptr $signal_name
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-css-name:
=begin pod
=head2 class-set-css-name

Sets the name to be used for CSS matching of widgets.

If this function is not called for a given class, the name set on the parent class is used. By default, `GtkWidget` uses the name "widget".

  method class-set-css-name ( GtkWidgetClass $widget_class, Str $name )

=item $widget_class; class to set the name on
=item $name; name to use
=end pod

method class-set-css-name ( GtkWidgetClass $widget_class, Str $name ) {
  gtk_widget_class_set_css_name( self._f('GtkWidget'), $widget_class, $name);
}

sub gtk_widget_class_set_css_name (
  GtkWidgetClass $widget_class, gchar-ptr $name
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-layout-manager-type:
=begin pod
=head2 class-set-layout-manager-type

Sets the type to be used for creating layout managers for widgets of I<widget_class>.

The given I<type> must be a subtype of [classI<Gtk>.LayoutManager].

This function should only be called from class init functions of widgets.

  method class-set-layout-manager-type ( GtkWidgetClass $widget_class, N-GObject() $type )

=item $widget_class; a `GtkWidgetClass`
=item $type; The object type that implements the `GtkLayoutManager` for I<widget_class>
=end pod

method class-set-layout-manager-type ( GtkWidgetClass $widget_class, N-GObject() $type ) {
  gtk_widget_class_set_layout_manager_type( self._f('GtkWidget'), $widget_class, $type);
}

sub gtk_widget_class_set_layout_manager_type (
  GtkWidgetClass $widget_class, N-GObject $type
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-template:
=begin pod
=head2 class-set-template

This should be called at class initialization time to specify the `GtkBuilder` XML to be used to extend a widget.

For convenience, [methodI<Gtk>.WidgetClass.set_template_from_resource] is also provided.

Note that any class that installs templates must call [methodI<Gtk>.Widget.init_template] in the widget’s instance initializer.

  method class-set-template ( GtkWidgetClass $widget_class, N-GObject() $template_bytes )

=item $widget_class; A `GtkWidgetClass`
=item $template_bytes; A `GBytes` holding the `GtkBuilder` XML
=end pod

method class-set-template ( GtkWidgetClass $widget_class, N-GObject() $template_bytes ) {
  gtk_widget_class_set_template( self._f('GtkWidget'), $widget_class, $template_bytes);
}

sub gtk_widget_class_set_template (
  GtkWidgetClass $widget_class, N-GObject $template_bytes
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-template-from-resource:
=begin pod
=head2 class-set-template-from-resource

A convenience function that calls [methodI<Gtk>.WidgetClass.set_template] with the contents of a `GResource`.

Note that any class that installs templates must call [methodI<Gtk>.Widget.init_template] in the widget’s instance initializer.

  method class-set-template-from-resource ( GtkWidgetClass $widget_class, Str $resource_name )

=item $widget_class; A `GtkWidgetClass`
=item $resource_name; The name of the resource to load the template from
=end pod

method class-set-template-from-resource ( GtkWidgetClass $widget_class, Str $resource_name ) {
  gtk_widget_class_set_template_from_resource( self._f('GtkWidget'), $widget_class, $resource_name);
}

sub gtk_widget_class_set_template_from_resource (
  GtkWidgetClass $widget_class, gchar-ptr $resource_name
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:class-set-template-scope:
=begin pod
=head2 class-set-template-scope

For use in language bindings, this will override the default `GtkBuilderScope` to be used when parsing GtkBuilder XML from this class’s template data.

Note that this must be called from a composite widget classes class initializer after calling [methodI<GtkWidgetClass>.set_template].

  method class-set-template-scope ( GtkWidgetClass $widget_class, GtkBuilderScope $scope )

=item $widget_class; A `GtkWidgetClass`
=item $scope; The `GtkBuilderScope` to use when loading the class template
=end pod

method class-set-template-scope ( GtkWidgetClass $widget_class, GtkBuilderScope $scope ) {
  gtk_widget_class_set_template_scope( self._f('GtkWidget'), $widget_class, $scope);
}

sub gtk_widget_class_set_template_scope (
  GtkWidgetClass $widget_class, GtkBuilderScope $scope
) is native(&gtk4-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:compute-bounds:
=begin pod
=head2 compute-bounds

Computes the bounds for I<widget> in the coordinate space of I<target>.

FIXME: Explain what "bounds" are.

If the operation is successful, C<True> is returned. If I<widget> has no bounds or the bounds cannot be expressed in I<target>'s coordinate space (for example if both widgets are in different windows), C<False> is returned and I<bounds> is set to the zero rectangle.

It is valid for I<widget> and I<target> to be the same widget.

Returns: C<True> if the bounds could be computed

  method compute-bounds ( N-GObject() $target, graphene_rect_t $out_bounds --> Bool )

=item $target; the `GtkWidget`
=item $out_bounds; (out caller-allocates): the rectangle taking the bounds
=end pod

method compute-bounds ( N-GObject() $target, graphene_rect_t $out_bounds --> Bool ) {
  gtk_widget_compute_bounds( self._f('GtkWidget'), $target, $out_bounds).Bool
}

sub gtk_widget_compute_bounds (
  N-GObject $widget, N-GObject $target, graphene_rect_t $out_bounds --> gboolean
) is native(&gtk4-lib)
  { * }
}}
#-------------------------------------------------------------------------------
#TM:0:compute-expand:
=begin pod
=head2 compute-expand

Computes whether a container should give this widget extra space when possible.

Containers should check this, rather than looking at [methodI<Gtk>.Widget.get_hexpand] or [methodI<Gtk>.Widget.get_vexpand].

This function already checks whether the widget is visible, so visibility does not need to be checked separately. Non-visible widgets are not expanded.

The computed expand value uses either the expand setting explicitly set on the widget itself, or, if none has been explicitly set, the widget may expand if some of its children do.

Returns: whether widget tree rooted here should be expanded

  method compute-expand ( GtkOrientation $orientation --> Bool )

=item $orientation; expand direction
=end pod

method compute-expand ( GtkOrientation $orientation --> Bool ) {
  gtk_widget_compute_expand( self._f('GtkWidget'), $orientation).Bool
}

sub gtk_widget_compute_expand (
  N-GObject $widget, GEnum $orientation --> gboolean
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:compute-point:
=begin pod
=head2 compute-point

Translates the given I<point> in I<widget>'s coordinates to coordinates relative to I<target>’s coordinate system.

In order to perform this operation, both widgets must share a common ancestor.

Returns: C<True> if the point could be determined, C<False> on failure. In this case, 0 is stored in I<out_point>.

  method compute-point ( N-GObject() $target, graphene_point_t $point, graphene_point_t $out_point --> Bool )

=item $target; the `GtkWidget` to transform into
=item $point; a point in I<widget>'s coordinate system
=item $out_point; (out caller-allocates): Set to the corresponding coordinates in I<target>'s coordinate system
=end pod

method compute-point ( N-GObject() $target, graphene_point_t $point, graphene_point_t $out_point --> Bool ) {
  gtk_widget_compute_point( self._f('GtkWidget'), $target, $point, $out_point).Bool
}

sub gtk_widget_compute_point (
  N-GObject $widget, N-GObject $target, graphene_point_t $point, graphene_point_t $out_point --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:compute-transform:
=begin pod
=head2 compute-transform

Computes a matrix suitable to describe a transformation from I<widget>'s coordinate system into I<target>'s coordinate system.

The transform can not be computed in certain cases, for example when I<widget> and I<target> do not share a common ancestor. In that case I<out_transform> gets set to the identity matrix.

Returns: C<True> if the transform could be computed, C<False> otherwise

  method compute-transform ( N-GObject() $target, graphene_matrix_t $out_transform --> Bool )

=item $target; the target widget that the matrix will transform to
=item $out_transform; (out caller-allocates): location to store the final transformation
=end pod

method compute-transform ( N-GObject() $target, graphene_matrix_t $out_transform --> Bool ) {
  gtk_widget_compute_transform( self._f('GtkWidget'), $target, $out_transform).Bool
}

sub gtk_widget_compute_transform (
  N-GObject $widget, N-GObject $target, graphene_matrix_t $out_transform --> gboolean
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:contains:
=begin pod
=head2 contains

Tests if the point at (I<x>, I<y>) is contained in I<widget>.

The coordinates for (I<x>, I<y>) must be in widget coordinates, so (0, 0) is assumed to be the top left of I<widget>'s content area.

Returns: C<True> if I<widget> contains (I<x>, I<y>).

  method contains ( double $x, double $y --> Bool )

=item $x; X coordinate to test, relative to I<widget>'s origin
=item $y; Y coordinate to test, relative to I<widget>'s origin
=end pod

method contains ( Num $x, Num $y --> Bool ) {
  gtk_widget_contains( self._f('GtkWidget'), $x, $y).Bool
}

sub gtk_widget_contains (
  N-GObject $widget, gdouble $x, gdouble $y --> gboolean
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:create-pango-context:
=begin pod
=head2 create-pango-context

Creates a new `PangoContext` with the appropriate font map, font options, font description, and base direction for drawing text for this widget.

See also [methodI<Gtk>.Widget.get_pango_context].

Returns: the new `PangoContext`

  method create-pango-context ( --> N-GObject )

=end pod

method create-pango-context ( --> N-GObject ) {
  gtk_widget_create_pango_context( self._f('GtkWidget'))
}

sub gtk_widget_create_pango_context (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:create-pango-layout:
=begin pod
=head2 create-pango-layout

Creates a new `PangoLayout` with the appropriate font map, font description, and base direction for drawing text for this widget.

If you keep a `PangoLayout` created in this way around, you need to re-create it when the widget `PangoContext` is replaced. This can be tracked by listening to changes of the [propertyI<Gtk>.Widget:root] property on the widget.

Returns: the new `PangoLayout`

  method create-pango-layout ( Str $text --> N-GObject )

=item $text; text to set on the layout
=end pod

method create-pango-layout ( Str $text --> N-GObject ) {
  gtk_widget_create_pango_layout( self._f('GtkWidget'), $text)
}

sub gtk_widget_create_pango_layout (
  N-GObject $widget, gchar-ptr $text --> N-GObject
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:error-bell:
=begin pod
=head2 error-bell

Notifies the user about an input-related error on this widget.

If the [propertyI<Gtk>.Settings:gtk-error-bell] setting is C<True>, it calls [methodI<Gdk>.Surface.beep], otherwise it does nothing.

Note that the effect of [methodI<Gdk>.Surface.beep] can be configured in many ways, depending on the windowing backend and the desktop environment or window manager that is used.

  method error-bell ( )

=end pod

method error-bell ( ) {
  gtk_widget_error_bell( self._f('GtkWidget'));
}

sub gtk_widget_error_bell (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-allocated-baseline:
=begin pod
=head2 get-allocated-baseline

Returns the baseline that has currently been allocated to I<widget>.

This function is intended to be used when implementing handlers for the `GtkWidget`Class.C<snapshot()> function, and when allocating child widgets in `GtkWidget`Class.C<size_allocate()>.

Returns: the baseline of the I<widget>, or -1 if none

  method get-allocated-baseline ( --> Int )

=end pod

method get-allocated-baseline ( --> Int ) {
  gtk_widget_get_allocated_baseline( self._f('GtkWidget'))
}

sub gtk_widget_get_allocated_baseline (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-allocated-height:
=begin pod
=head2 get-allocated-height

Returns the height that has currently been allocated to I<widget>.

Returns: the height of the I<widget>

  method get-allocated-height ( --> Int )

=end pod

method get-allocated-height ( --> Int ) {
  gtk_widget_get_allocated_height( self._f('GtkWidget'))
}

sub gtk_widget_get_allocated_height (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-allocated-width:
=begin pod
=head2 get-allocated-width

Returns the width that has currently been allocated to I<widget>.

Returns: the width of the I<widget>

  method get-allocated-width ( --> Int )

=end pod

method get-allocated-width ( --> Int ) {
  gtk_widget_get_allocated_width( self._f('GtkWidget'))
}

sub gtk_widget_get_allocated_width (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:get-allocation:
=begin pod
=head2 get-allocation

Retrieves the widget’s allocation.

Note, when implementing a layout container: a widget’s allocation will be its “adjusted” allocation, that is, the widget’s parent typically calls [methodI<Gtk>.Widget.size_allocate] with an allocation, and that allocation is then adjusted (to handle margin and alignment for example) before assignment to the widget. [methodI<Gtk>.Widget.get_allocation] returns the adjusted allocation that was actually assigned to the widget. The adjusted allocation is guaranteed to be completely contained within the [methodI<Gtk>.Widget.size_allocate] allocation, however.

So a layout container is guaranteed that its children stay inside the assigned bounds, but not that they have exactly the bounds the container assigned.

  method get-allocation ( GtkAllocation $allocation )

=item $allocation; a pointer to a `GtkAllocation` to copy to
=end pod

method get-allocation ( GtkAllocation $allocation ) {
  gtk_widget_get_allocation( self._f('GtkWidget'), $allocation);
}

sub gtk_widget_get_allocation (
  N-GObject $widget, GtkAllocation $allocation
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:get-ancestor:
=begin pod
=head2 get-ancestor

Gets the first ancestor of I<widget> with type I<widget_type>.

For example, `get_ancestor (widget, GTK_TYPE_BOX)` gets the first `GtkBox` that’s an ancestor of I<widget>. No reference will be added to the returned widget; it should not be unreferenced.

Note that unlike [methodI<Gtk>.Widget.is_ancestor], this function considers I<widget> to be an ancestor of itself.

Returns: the ancestor widget

  method get-ancestor ( N-GObject() $widget_type --> N-GObject )

=item $widget_type; ancestor type
=end pod

method get-ancestor ( N-GObject() $widget_type --> N-GObject ) {
  gtk_widget_get_ancestor( self._f('GtkWidget'), $widget_type)
}

sub gtk_widget_get_ancestor (
  N-GObject $widget, N-GObject $widget_type --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-can-focus:
=begin pod
=head2 get-can-focus

Determines whether the input focus can enter I<widget> or any of its children.

See [methodI<Gtk>.Widget.set_focusable].

Returns: C<True> if the input focus can enter I<widget>, C<False> otherwise

  method get-can-focus ( --> Bool )

=end pod

method get-can-focus ( --> Bool ) {
  gtk_widget_get_can_focus( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_can_focus (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-can-target:
=begin pod
=head2 get-can-target

Queries whether I<widget> can be the target of pointer events.

Returns: C<True> if I<widget> can receive pointer events

  method get-can-target ( --> Bool )

=end pod

method get-can-target ( --> Bool ) {
  gtk_widget_get_can_target( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_can_target (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-child-visible:
=begin pod
=head2 get-child-visible

Gets the value set with C<set_child_visible()>.

If you feel a need to use this function, your code probably needs reorganization.

This function is only useful for container implementations and should never be called by an application.

Returns: C<True> if the widget is mapped with the parent.

  method get-child-visible ( --> Bool )

=end pod

method get-child-visible ( --> Bool ) {
  gtk_widget_get_child_visible( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_child_visible (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:get-clipboard:
=begin pod
=head2 get-clipboard

Gets the clipboard object for I<widget>.

This is a utility function to get the clipboard object for the `GdkDisplay` that I<widget> is using.

Note that this function always works, even when I<widget> is not realized yet.

Returns: the appropriate clipboard object

  method get-clipboard ( --> GdkClipboard )

=end pod

method get-clipboard ( --> GdkClipboard ) {
  gtk_widget_get_clipboard( self._f('GtkWidget'))
}

sub gtk_widget_get_clipboard (
  N-GObject $widget --> GdkClipboard
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:get-css-classes:
=begin pod
=head2 get-css-classes

Returns the list of style classes applied to I<widget>.

Returns: a C<undefined>-terminated list of css classes currently applied to I<widget>. The returned list must freed using C<g_strfreev()>.

  method get-css-classes ( --> CArray[Str] )

=end pod

method get-css-classes ( --> CArray[Str] ) {
  gtk_widget_get_css_classes( self._f('GtkWidget'))
}

sub gtk_widget_get_css_classes (
  N-GObject $widget --> gchar-pptr
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-css-name:
=begin pod
=head2 get-css-name

Returns the CSS name that is used for I<self>.

Returns: the CSS name

  method get-css-name ( --> Str )

=end pod

method get-css-name ( --> Str ) {
  gtk_widget_get_css_name( self._f('GtkWidget'))
}

sub gtk_widget_get_css_name (
  N-GObject $self --> gchar-ptr
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-cursor:
=begin pod
=head2 get-cursor

Queries the cursor set on I<widget>.

See [methodI<Gtk>.Widget.set_cursor] for details.

Returns: the cursor currently in use or C<undefined> if the cursor is inherited

  method get-cursor ( --> N-GObject )

=end pod

method get-cursor ( --> N-GObject ) {
  gtk_widget_get_cursor( self._f('GtkWidget'))
}

sub gtk_widget_get_cursor (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-default-direction:
=begin pod
=head2 get-default-direction

Obtains the current default reading direction.

See [funcI<Gtk>.Widget.set_default_direction].

Returns: the current default direction.

  method get-default-direction ( --> GtkTextDirection )

=end pod

method get-default-direction ( --> GtkTextDirection ) {
  gtk_widget_get_default_direction( self._f('GtkWidget'))
}

sub gtk_widget_get_default_direction (
   --> GEnum
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-direction:
=begin pod
=head2 get-direction

Gets the reading direction for a particular widget.

See [methodI<Gtk>.Widget.set_direction].

Returns: the reading direction for the widget.

  method get-direction ( --> GtkTextDirection )

=end pod

method get-direction ( --> GtkTextDirection ) {
  gtk_widget_get_direction( self._f('GtkWidget'))
}

sub gtk_widget_get_direction (
  N-GObject $widget --> GEnum
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-display:
=begin pod
=head2 get-display

Get the `GdkDisplay` for the toplevel window associated with this widget.

This function can only be called after the widget has been added to a widget hierarchy with a `GtkWindow` at the top.

In general, you should only create display specific resources when a widget has been realized, and you should free those resources when the widget is unrealized.

Returns: the `GdkDisplay` for the toplevel for this widget.

  method get-display ( --> N-GObject )

=end pod

method get-display ( --> N-GObject ) {
  gtk_widget_get_display( self._f('GtkWidget'))
}

sub gtk_widget_get_display (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-first-child:
=begin pod
=head2 get-first-child

Returns the widgets first child.

This API is primarily meant for widget implementations.

Returns: The widget's first child

  method get-first-child ( --> N-GObject )

=end pod

method get-first-child ( --> N-GObject ) {
  gtk_widget_get_first_child( self._f('GtkWidget'))
}

sub gtk_widget_get_first_child (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-focus-child:
=begin pod
=head2 get-focus-child

Returns the current focus child of I<widget>.

Returns: The current focus child of I<widget>

  method get-focus-child ( --> N-GObject )

=end pod

method get-focus-child ( --> N-GObject ) {
  gtk_widget_get_focus_child( self._f('GtkWidget'))
}

sub gtk_widget_get_focus_child (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-focus-on-click:
=begin pod
=head2 get-focus-on-click

Returns whether the widget should grab focus when it is clicked with the mouse.

See [methodI<Gtk>.Widget.set_focus_on_click].

Returns: C<True> if the widget should grab focus when it is clicked with the mouse

  method get-focus-on-click ( --> Bool )

=end pod

method get-focus-on-click ( --> Bool ) {
  gtk_widget_get_focus_on_click( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_focus_on_click (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-focusable:
=begin pod
=head2 get-focusable

Determines whether I<widget> can own the input focus.

See [methodI<Gtk>.Widget.set_focusable].

Returns: C<True> if I<widget> can own the input focus, C<False> otherwise

  method get-focusable ( --> Bool )

=end pod

method get-focusable ( --> Bool ) {
  gtk_widget_get_focusable( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_focusable (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-font-map:
=begin pod
=head2 get-font-map

Gets the font map of I<widget>.

See [methodI<Gtk>.Widget.set_font_map].

Returns: A `PangoFontMap`

  method get-font-map ( --> N-GObject )

=end pod

method get-font-map ( --> N-GObject ) {
  gtk_widget_get_font_map( self._f('GtkWidget'))
}

sub gtk_widget_get_font_map (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-font-options:
=begin pod
=head2 get-font-options

Returns the `cairo_font_options_t` of widget.

Seee [methodI<Gtk>.Widget.set_font_options].

Returns: the `cairo_font_options_t` of widget

  method get-font-options ( --> cairo_font_options_t )

=end pod

method get-font-options ( --> cairo_font_options_t ) {
  gtk_widget_get_font_options( self._f('GtkWidget'))
}

sub gtk_widget_get_font_options (
  N-GObject $widget --> cairo_font_options_t
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-frame-clock:
=begin pod
=head2 get-frame-clock

Obtains the frame clock for a widget.

The frame clock is a global “ticker” that can be used to drive animations and repaints. The most common reason to get the frame clock is to call [methodI<Gdk>.FrameClock.get_frame_time], in order to get a time to use for animating. For example you might record the start of the animation with an initial value from [methodI<Gdk>.FrameClock.get_frame_time], and then update the animation by calling [methodI<Gdk>.FrameClock.get_frame_time] again during each repaint.

[methodI<Gdk>.FrameClock.request_phase] will result in a new frame on the clock, but won’t necessarily repaint any widgets. To repaint a widget, you have to use [methodI<Gtk>.Widget.queue_draw] which invalidates the widget (thus scheduling it to receive a draw on the next frame). C<queue_draw()> will also end up requesting a frame on the appropriate frame clock.

A widget’s frame clock will not change while the widget is mapped. Reparenting a widget (which implies a temporary unmap) can change the widget’s frame clock.

Unrealized widgets do not have a frame clock.

Returns: a `GdkFrameClock`

  method get-frame-clock ( --> N-GObject )

=end pod

method get-frame-clock ( --> N-GObject ) {
  gtk_widget_get_frame_clock( self._f('GtkWidget'))
}

sub gtk_widget_get_frame_clock (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-halign:
=begin pod
=head2 get-halign

Gets the horizontal alignment of I<widget>.

For backwards compatibility reasons this method will never return C<GTK_ALIGN_BASELINE>, but instead it will convert it to C<GTK_ALIGN_FILL>. Baselines are not supported for horizontal alignment.

Returns: the horizontal alignment of I<widget>

  method get-halign ( --> GtkAlign )

=end pod

method get-halign ( --> GtkAlign ) {
  gtk_widget_get_halign( self._f('GtkWidget'))
}

sub gtk_widget_get_halign (
  N-GObject $widget --> GEnum
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-has-tooltip:
=begin pod
=head2 get-has-tooltip

Returns the current value of the `has-tooltip` property.

Returns: current value of `has-tooltip` on I<widget>.

  method get-has-tooltip ( --> Bool )

=end pod

method get-has-tooltip ( --> Bool ) {
  gtk_widget_get_has_tooltip( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_has_tooltip (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-height:
=begin pod
=head2 get-height

Returns the content height of the widget.

This function returns the height passed to its size-allocate implementation, which is the height you should be using in [vfuncI<Gtk>.Widget.snapshot].

For pointer events, see [methodI<Gtk>.Widget.contains].

Returns: The height of I<widget>

  method get-height ( --> Int )

=end pod

method get-height ( --> Int ) {
  gtk_widget_get_height( self._f('GtkWidget'))
}

sub gtk_widget_get_height (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-hexpand:
=begin pod
=head2 get-hexpand

Gets whether the widget would like any available extra horizontal space.

When a user resizes a `GtkWindow`, widgets with expand=TRUE generally receive the extra space. For example, a list or scrollable area or document in your window would often be set to expand.

Containers should use [methodI<Gtk>.Widget.compute_expand] rather than this function, to see whether a widget, or any of its children, has the expand flag set. If any child of a widget wants to expand, the parent may ask to expand also.

This function only looks at the widget’s own hexpand flag, rather than computing whether the entire widget tree rooted at this widget wants to expand.

Returns: whether hexpand flag is set

  method get-hexpand ( --> Bool )

=end pod

method get-hexpand ( --> Bool ) {
  gtk_widget_get_hexpand( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_hexpand (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-hexpand-set:
=begin pod
=head2 get-hexpand-set

Gets whether C<set_hexpand()> has been used to explicitly set the expand flag on this widget.

If [propertyI<Gtk>.Widget:hexpand] property is set, then it overrides any computed expand value based on child widgets. If `hexpand` is not set, then the expand value depends on whether any children of the widget would like to expand.

There are few reasons to use this function, but it’s here for completeness and consistency.

Returns: whether hexpand has been explicitly set

  method get-hexpand-set ( --> Bool )

=end pod

method get-hexpand-set ( --> Bool ) {
  gtk_widget_get_hexpand_set( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_hexpand_set (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-last-child:
=begin pod
=head2 get-last-child

Returns the widgets last child.

This API is primarily meant for widget implementations.

Returns: The widget's last child

  method get-last-child ( --> N-GObject )

=end pod

method get-last-child ( --> N-GObject ) {
  gtk_widget_get_last_child( self._f('GtkWidget'))
}

sub gtk_widget_get_last_child (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-layout-manager:
=begin pod
=head2 get-layout-manager

Retrieves the layout manager used by I<widget>.

See [methodI<Gtk>.Widget.set_layout_manager].

Returns: a `GtkLayoutManager`

  method get-layout-manager ( --> GtkLayoutManager )

=end pod

method get-layout-manager ( --> GtkLayoutManager ) {
  gtk_widget_get_layout_manager( self._f('GtkWidget'))
}

sub gtk_widget_get_layout_manager (
  N-GObject $widget --> GtkLayoutManager
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-mapped:
=begin pod
=head2 get-mapped

Whether the widget is mapped.

Returns: C<True> if the widget is mapped, C<False> otherwise.

  method get-mapped ( --> Bool )

=end pod

method get-mapped ( --> Bool ) {
  gtk_widget_get_mapped( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_mapped (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-margin-bottom:
=begin pod
=head2 get-margin-bottom

Gets the bottom margin of I<widget>.

Returns: The bottom margin of I<widget>

  method get-margin-bottom ( --> Int )

=end pod

method get-margin-bottom ( --> Int ) {
  gtk_widget_get_margin_bottom( self._f('GtkWidget'))
}

sub gtk_widget_get_margin_bottom (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-margin-end:
=begin pod
=head2 get-margin-end

Gets the end margin of I<widget>.

Returns: The end margin of I<widget>

  method get-margin-end ( --> Int )

=end pod

method get-margin-end ( --> Int ) {
  gtk_widget_get_margin_end( self._f('GtkWidget'))
}

sub gtk_widget_get_margin_end (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-margin-start:
=begin pod
=head2 get-margin-start

Gets the start margin of I<widget>.

Returns: The start margin of I<widget>

  method get-margin-start ( --> Int )

=end pod

method get-margin-start ( --> Int ) {
  gtk_widget_get_margin_start( self._f('GtkWidget'))
}

sub gtk_widget_get_margin_start (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-margin-top:
=begin pod
=head2 get-margin-top

Gets the top margin of I<widget>.

Returns: The top margin of I<widget>

  method get-margin-top ( --> Int )

=end pod

method get-margin-top ( --> Int ) {
  gtk_widget_get_margin_top( self._f('GtkWidget'))
}

sub gtk_widget_get_margin_top (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-name:
=begin pod
=head2 get-name

Retrieves the name of a widget.

See [methodI<Gtk>.Widget.set_name] for the significance of widget names.

Returns: name of the widget. This string is owned by GTK and should not be modified or freed

  method get-name ( --> Str )

=end pod

method get-name ( --> Str ) {
  gtk_widget_get_name( self._f('GtkWidget'))
}

sub gtk_widget_get_name (
  N-GObject $widget --> gchar-ptr
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-native:
=begin pod
=head2 get-native

Returns the nearest `GtkNative` ancestor of I<widget>.

This function will return C<undefined> if the widget is not contained inside a widget tree with a native ancestor.

`GtkNative` widgets will return themselves here.

Returns: the `GtkNative` ancestor of I<widget>

  method get-native ( --> GtkNative )

=end pod

method get-native ( --> GtkNative ) {
  gtk_widget_get_native( self._f('GtkWidget'))
}

sub gtk_widget_get_native (
  N-GObject $widget --> GtkNative
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-next-sibling:
=begin pod
=head2 get-next-sibling

Returns the widgets next sibling.

This API is primarily meant for widget implementations.

Returns: The widget's next sibling

  method get-next-sibling ( --> N-GObject )

=end pod

method get-next-sibling ( --> N-GObject ) {
  gtk_widget_get_next_sibling( self._f('GtkWidget'))
}

sub gtk_widget_get_next_sibling (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-opacity:
=begin pod
=head2 get-opacity

B<Fetches> the requested opacity for this widget.

See [methodI<Gtk>.Widget.set_opacity].

Returns: the requested opacity for this widget.

  method get-opacity ( --> double )

=end pod

method get-opacity ( --> double ) {
  gtk_widget_get_opacity( self._f('GtkWidget'))
}

sub gtk_widget_get_opacity (
  N-GObject $widget --> double
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-overflow:
=begin pod
=head2 get-overflow

Returns the widgets overflow value.

Returns: The widget's overflow.

  method get-overflow ( --> GtkOverflow )

=end pod

method get-overflow ( --> GtkOverflow ) {
  gtk_widget_get_overflow( self._f('GtkWidget'))
}

sub gtk_widget_get_overflow (
  N-GObject $widget --> GtkOverflow
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-pango-context:
=begin pod
=head2 get-pango-context

Gets a `PangoContext` with the appropriate font map, font description, and base direction for this widget.

Unlike the context returned by [methodI<Gtk>.Widget.create_pango_context], this context is owned by the widget (it can be used until the screen for the widget changes or the widget is removed from its toplevel), and will be updated to match any changes to the widget’s attributes. This can be tracked by listening to changes of the [propertyI<Gtk>.Widget:root] property on the widget.

Returns: the `PangoContext` for the widget.

  method get-pango-context ( --> N-GObject )

=end pod

method get-pango-context ( --> N-GObject ) {
  gtk_widget_get_pango_context( self._f('GtkWidget'))
}

sub gtk_widget_get_pango_context (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-parent:
=begin pod
=head2 get-parent

Returns the parent widget of I<widget>.

Returns: the parent widget of I<widget>

  method get-parent ( --> N-GObject )

=end pod

method get-parent ( --> N-GObject ) {
  gtk_widget_get_parent( self._f('GtkWidget'))
}

sub gtk_widget_get_parent (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-preferred-size:
=begin pod
=head2 get-preferred-size



  method get-preferred-size ( GtkRequisition $minimum_size, GtkRequisition $natural_size )

=item $minimum_size;
=item $natural_size;
=end pod

method get-preferred-size ( GtkRequisition $minimum_size, GtkRequisition $natural_size ) {
  gtk_widget_get_preferred_size( self._f('GtkWidget'), $minimum_size, $natural_size);
}

sub gtk_widget_get_preferred_size (
  N-GObject $widget, GtkRequisition $minimum_size, GtkRequisition $natural_size
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-prev-sibling:
=begin pod
=head2 get-prev-sibling

Returns the widgets previous sibling.

This API is primarily meant for widget implementations.

Returns: The widget's previous sibling

  method get-prev-sibling ( --> N-GObject )

=end pod

method get-prev-sibling ( --> N-GObject ) {
  gtk_widget_get_prev_sibling( self._f('GtkWidget'))
}

sub gtk_widget_get_prev_sibling (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:get-primary-clipboard:
=begin pod
=head2 get-primary-clipboard

Gets the primary clipboard of I<widget>.

This is a utility function to get the primary clipboard object for the `GdkDisplay` that I<widget> is using.

Note that this function always works, even when I<widget> is not realized yet.

Returns: the appropriate clipboard object

  method get-primary-clipboard ( --> GdkClipboard )

=end pod

method get-primary-clipboard ( --> GdkClipboard ) {
  gtk_widget_get_primary_clipboard( self._f('GtkWidget'))
}

sub gtk_widget_get_primary_clipboard (
  N-GObject $widget --> GdkClipboard
) is native(&gtk4-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:get-realized:
=begin pod
=head2 get-realized

Determines whether I<widget> is realized.

Returns: C<True> if I<widget> is realized, C<False> otherwise

  method get-realized ( --> Bool )

=end pod

method get-realized ( --> Bool ) {
  gtk_widget_get_realized( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_realized (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-receives-default:
=begin pod
=head2 get-receives-default

Determines whether I<widget> is always treated as the default widget within its toplevel when it has the focus, even if another widget is the default.

See [methodI<Gtk>.Widget.set_receives_default].

Returns: C<True> if I<widget> acts as the default widget when focused, C<False> otherwise

  method get-receives-default ( --> Bool )

=end pod

method get-receives-default ( --> Bool ) {
  gtk_widget_get_receives_default( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_receives_default (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-request-mode:
=begin pod
=head2 get-request-mode



  method get-request-mode ( --> GtkSizeRequestMode )

=end pod

method get-request-mode ( --> GtkSizeRequestMode ) {
  gtk_widget_get_request_mode( self._f('GtkWidget'))
}

sub gtk_widget_get_request_mode (
  N-GObject $widget --> GEnum
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-root:
=begin pod
=head2 get-root

Returns the `GtkRoot` widget of I<widget>.

This function will return C<undefined> if the widget is not contained inside a widget tree with a root widget.

`GtkRoot` widgets will return themselves here.

Returns: the root widget of I<widget>

  method get-root ( --> GtkRoot )

=end pod

method get-root ( --> GtkRoot ) {
  gtk_widget_get_root( self._f('GtkWidget'))
}

sub gtk_widget_get_root (
  N-GObject $widget --> GtkRoot
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-scale-factor:
=begin pod
=head2 get-scale-factor

Retrieves the internal scale factor that maps from window coordinates to the actual device pixels.

On traditional systems this is 1, on high density outputs, it can be a higher value (typically 2).

See [methodI<Gdk>.Surface.get_scale_factor].

Returns: the scale factor for I<widget>

  method get-scale-factor ( --> Int )

=end pod

method get-scale-factor ( --> Int ) {
  gtk_widget_get_scale_factor( self._f('GtkWidget'))
}

sub gtk_widget_get_scale_factor (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-sensitive:
=begin pod
=head2 get-sensitive

Returns the widget’s sensitivity.

This function returns the value that has been set using [methodI<Gtk>.Widget.set_sensitive]).

The effective sensitivity of a widget is however determined by both its own and its parent widget’s sensitivity. See [methodI<Gtk>.Widget.is_sensitive].

Returns: C<True> if the widget is sensitive

  method get-sensitive ( --> Bool )

=end pod

method get-sensitive ( --> Bool ) {
  gtk_widget_get_sensitive( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_sensitive (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-settings:
=begin pod
=head2 get-settings

Gets the settings object holding the settings used for this widget.

Note that this function can only be called when the `GtkWidget` is attached to a toplevel, since the settings object is specific to a particular `GdkDisplay`. If you want to monitor the widget for changes in its settings, connect to the `notify::display` signal.

Returns: the relevant `GtkSettings` object

  method get-settings ( --> N-GObject )

=end pod

method get-settings ( --> N-GObject ) {
  gtk_widget_get_settings( self._f('GtkWidget'))
}

sub gtk_widget_get_settings (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-size:
=begin pod
=head2 get-size

Returns the content width or height of the widget.

Which dimension is returned depends on I<orientation>.

This is equivalent to calling [methodI<Gtk>.Widget.get_width] for C<GTK_ORIENTATION_HORIZONTAL> or [methodI<Gtk>.Widget.get_height] for C<GTK_ORIENTATION_VERTICAL>, but can be used when writing orientation-independent code, such as when implementing [ifaceI<Gtk>.Orientable] widgets.

Returns: The size of I<widget> in I<orientation>.

  method get-size ( GtkOrientation $orientation --> Int )

=item $orientation; the orientation to query
=end pod

method get-size ( GtkOrientation $orientation --> Int ) {
  gtk_widget_get_size( self._f('GtkWidget'), $orientation)
}

sub gtk_widget_get_size (
  N-GObject $widget, GEnum $orientation --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-size-request:
=begin pod
=head2 get-size-request

Gets the size request that was explicitly set for the widget using C<set_size_request()>.

A value of -1 stored in I<width> or I<height> indicates that that dimension has not been set explicitly and the natural requisition of the widget will be used instead. See [methodI<Gtk>.Widget.set_size_request]. To get the size a widget will actually request, call [methodI<Gtk>.Widget.measure] instead of this function.

  method get-size-request ( )

=item $width; return location for width
=item $height; return location for height
=end pod

method get-size-request ( ) {
  gtk_widget_get_size_request( self._f('GtkWidget'), my gint $width, my gint $height);
}

sub gtk_widget_get_size_request (
  N-GObject $widget, gint $width is rw, gint $height is rw
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-state-flags:
=begin pod
=head2 get-state-flags

Returns the widget state as a flag set.

It is worth mentioning that the effective C<GTK_STATE_FLAG_INSENSITIVE> state will be returned, that is, also based on parent insensitivity, even if I<widget> itself is sensitive.

Also note that if you are looking for a way to obtain the [flagsI<Gtk>.StateFlags] to pass to a [classI<Gtk>.StyleContext] method, you should look at [methodI<Gtk>.StyleContext.get_state].

Returns: The state flags for widget

  method get-state-flags ( --> GtkStateFlags )

=end pod

method get-state-flags ( --> GtkStateFlags ) {
  gtk_widget_get_state_flags( self._f('GtkWidget'))
}

sub gtk_widget_get_state_flags (
  N-GObject $widget --> GEnum
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-style-context:
=begin pod
=head2 get-style-context

Returns the style context associated to I<widget>.

The returned object is guaranteed to be the same for the lifetime of I<widget>.

Returns: the widgets `GtkStyleContext`

  method get-style-context ( --> N-GObject )

=end pod

method get-style-context ( --> N-GObject ) {
  gtk_widget_get_style_context( self._f('GtkWidget'))
}

sub gtk_widget_get_style_context (
  N-GObject $widget --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-template-child:
=begin pod
=head2 get-template-child

Fetch an object build from the template XML for I<widget_type> in this I<widget> instance.

This will only report children which were previously declared with [methodI<Gtk>.WidgetClass.bind_template_child_full] or one of its variants.

This function is only meant to be called for code which is private to the I<widget_type> which declared the child and is meant for language bindings which cannot easily make use of the GObject structure offsets.

Returns: The object built in the template XML with the id I<name>

  method get-template-child ( N-GObject() $widget_type, Str $name --> N-GObject )

=item $widget_type; The `GType` to get a template child for
=item $name; The “id” of the child defined in the template XML
=end pod

method get-template-child ( N-GObject() $widget_type, Str $name --> N-GObject ) {
  gtk_widget_get_template_child( self._f('GtkWidget'), $widget_type, $name)
}

sub gtk_widget_get_template_child (
  N-GObject $widget, N-GObject $widget_type, gchar-ptr $name --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-tooltip-markup:
=begin pod
=head2 get-tooltip-markup

Gets the contents of the tooltip for I<widget>.

If the tooltip has not been set using [methodI<Gtk>.Widget.set_tooltip_markup], this function returns C<undefined>.

Returns: the tooltip text

  method get-tooltip-markup ( --> Str )

=end pod

method get-tooltip-markup ( --> Str ) {
  gtk_widget_get_tooltip_markup( self._f('GtkWidget'))
}

sub gtk_widget_get_tooltip_markup (
  N-GObject $widget --> gchar-ptr
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-tooltip-text:
=begin pod
=head2 get-tooltip-text

Gets the contents of the tooltip for I<widget>.

If the I<widget>'s tooltip was set using [methodI<Gtk>.Widget.set_tooltip_markup], this function will return the escaped text.

Returns: the tooltip text

  method get-tooltip-text ( --> Str )

=end pod

method get-tooltip-text ( --> Str ) {
  gtk_widget_get_tooltip_text( self._f('GtkWidget'))
}

sub gtk_widget_get_tooltip_text (
  N-GObject $widget --> gchar-ptr
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-valign:
=begin pod
=head2 get-valign

Gets the vertical alignment of I<widget>.

Returns: the vertical alignment of I<widget>

  method get-valign ( --> GtkAlign )

=end pod

method get-valign ( --> GtkAlign ) {
  gtk_widget_get_valign( self._f('GtkWidget'))
}

sub gtk_widget_get_valign (
  N-GObject $widget --> GEnum
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-vexpand:
=begin pod
=head2 get-vexpand

Gets whether the widget would like any available extra vertical space.

See [methodI<Gtk>.Widget.get_hexpand] for more detail.

Returns: whether vexpand flag is set

  method get-vexpand ( --> Bool )

=end pod

method get-vexpand ( --> Bool ) {
  gtk_widget_get_vexpand( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_vexpand (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-vexpand-set:
=begin pod
=head2 get-vexpand-set

Gets whether C<set_vexpand()> has been used to explicitly set the expand flag on this widget.

See [methodI<Gtk>.Widget.get_hexpand_set] for more detail.

Returns: whether vexpand has been explicitly set

  method get-vexpand-set ( --> Bool )

=end pod

method get-vexpand-set ( --> Bool ) {
  gtk_widget_get_vexpand_set( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_vexpand_set (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-visible:
=begin pod
=head2 get-visible

Determines whether the widget is visible.

If you want to take into account whether the widget’s parent is also marked as visible, use [methodI<Gtk>.Widget.is_visible] instead.

This function does not check if the widget is obscured in any way.

See [methodI<Gtk>.Widget.set_visible].

Returns: C<True> if the widget is visible

  method get-visible ( --> Bool )

=end pod

method get-visible ( --> Bool ) {
  gtk_widget_get_visible( self._f('GtkWidget')).Bool
}

sub gtk_widget_get_visible (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:get-width:
=begin pod
=head2 get-width

Returns the content width of the widget.

This function returns the width passed to its size-allocate implementation, which is the width you should be using in [vfuncI<Gtk>.Widget.snapshot].

For pointer events, see [methodI<Gtk>.Widget.contains].

Returns: The width of I<widget>

  method get-width ( --> Int )

=end pod

method get-width ( --> Int ) {
  gtk_widget_get_width( self._f('GtkWidget'))
}

sub gtk_widget_get_width (
  N-GObject $widget --> gint
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:grab-focus:
=begin pod
=head2 grab-focus

Causes I<widget> to have the keyboard focus for the `GtkWindow` it's inside.

If I<widget> is not focusable, or its [vfuncI<Gtk>.Widget.grab_focus] implementation cannot transfer the focus to a descendant of I<widget> that is focusable, it will not take focus and C<False> will be returned.

Calling [methodI<Gtk>.Widget.grab_focus] on an already focused widget is allowed, should not have an effect, and return C<True>.

Returns: C<True> if focus is now inside I<widget>.

  method grab-focus ( --> Bool )

=end pod

method grab-focus ( --> Bool ) {
  gtk_widget_grab_focus( self._f('GtkWidget')).Bool
}

sub gtk_widget_grab_focus (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:gtk-requisition-copy:
=begin pod
=head2 gtk-requisition-copy

Copies a `GtkRequisition`.

Returns: a copy of I<requisition>

  method gtk-requisition-copy ( GtkRequisition $requisition --> GtkRequisition )

=item $requisition; a `GtkRequisition`
=end pod

method gtk-requisition-copy ( GtkRequisition $requisition --> GtkRequisition ) {
  gtk_requisition_copy( self._f('GtkWidget'), $requisition)
}

sub gtk_requisition_copy (
  GtkRequisition $requisition --> GtkRequisition
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:gtk-requisition-free:
=begin pod
=head2 gtk-requisition-free

Frees a `GtkRequisition`.

  method gtk-requisition-free ( GtkRequisition $requisition )

=item $requisition; a `GtkRequisition`
=end pod

method gtk-requisition-free ( GtkRequisition $requisition ) {
  gtk_requisition_free( self._f('GtkWidget'), $requisition);
}

sub gtk_requisition_free (
  GtkRequisition $requisition
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:gtk-requisition-new:
=begin pod
=head2 gtk-requisition-new

Allocates a new `GtkRequisition`.

The struct is initialized to zero.

Returns: a new empty `GtkRequisition`. The newly allocated `GtkRequisition` should be freed with [methodI<Gtk>.Requisition.free]

  method gtk-requisition-new ( G_GNUC_MALLO $C --> GtkRequisition )

=item $C;
=end pod

method gtk-requisition-new ( G_GNUC_MALLO $C --> GtkRequisition ) {
  gtk_requisition_new( self._f('GtkWidget'), $C)
}

sub gtk_requisition_new (
  G_GNUC_MALLO $C --> GtkRequisition
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:has-css-class:
=begin pod
=head2 has-css-class

Returns whether I<css_class> is currently applied to I<widget>.

Returns: C<True> if I<css_class> is currently applied to I<widget>, C<False> otherwise.

  method has-css-class ( Str $css_class --> Bool )

=item $css_class; A style class, without the leading '.' used for notation of style classes
=end pod

method has-css-class ( Str $css_class --> Bool ) {
  gtk_widget_has_css_class( self._f('GtkWidget'), $css_class).Bool
}

sub gtk_widget_has_css_class (
  N-GObject $widget, gchar-ptr $css_class --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:has-default:
=begin pod
=head2 has-default

Determines whether I<widget> is the current default widget within its toplevel.

Returns: C<True> if I<widget> is the current default widget within its toplevel, C<False> otherwise

  method has-default ( --> Bool )

=end pod

method has-default ( --> Bool ) {
  gtk_widget_has_default( self._f('GtkWidget')).Bool
}

sub gtk_widget_has_default (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:has-focus:
=begin pod
=head2 has-focus

Determines if the widget has the global input focus.

See [methodI<Gtk>.Widget.is_focus] for the difference between having the global input focus, and only having the focus within a toplevel.

Returns: C<True> if the widget has the global input focus.

  method has-focus ( --> Bool )

=end pod

method has-focus ( --> Bool ) {
  gtk_widget_has_focus( self._f('GtkWidget')).Bool
}

sub gtk_widget_has_focus (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:has-visible-focus:
=begin pod
=head2 has-visible-focus

Determines if the widget should show a visible indication that it has the global input focus.

This is a convenience function that takes into account whether focus indication should currently be shown in the toplevel window of I<widget>. See [methodI<Gtk>.Window.get_focus_visible] for more information about focus indication.

To find out if the widget has the global input focus, use [methodI<Gtk>.Widget.has_focus].

Returns: C<True> if the widget should display a “focus rectangle”

  method has-visible-focus ( --> Bool )

=end pod

method has-visible-focus ( --> Bool ) {
  gtk_widget_has_visible_focus( self._f('GtkWidget')).Bool
}

sub gtk_widget_has_visible_focus (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:hide:
=begin pod
=head2 hide

Reverses the effects of C<show()>.

This is causing the widget to be hidden (invisible to the user).

  method hide ( )

=end pod

method hide ( ) {
  gtk_widget_hide( self._f('GtkWidget'));
}

sub gtk_widget_hide (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:in-destruction:
=begin pod
=head2 in-destruction

Returns whether the widget is currently being destroyed.

This information can sometimes be used to avoid doing unnecessary work.

Returns: C<True> if I<widget> is being destroyed

  method in-destruction ( --> Bool )

=end pod

method in-destruction ( --> Bool ) {
  gtk_widget_in_destruction( self._f('GtkWidget')).Bool
}

sub gtk_widget_in_destruction (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:init-template:
=begin pod
=head2 init-template

Creates and initializes child widgets defined in templates.

This function must be called in the instance initializer for any class which assigned itself a template using [methodI<Gtk>.WidgetClass.set_template].

It is important to call this function in the instance initializer of a `GtkWidget` subclass and not in `GObject.C<constructed()>` or `GObject.C<constructor()>` for two reasons:

- derived widgets will assume that the composite widgets defined by its parent classes have been created in their relative instance initializers - when calling `C<g_object_new()>` on a widget with composite templates, it’s important to build the composite widgets before the construct properties are set. Properties passed to `C<g_object_new()>` should take precedence over properties set in the private template XML

A good rule of thumb is to call this function as the first thing in an instance initialization function.

  method init-template ( )

=end pod

method init-template ( ) {
  gtk_widget_init_template( self._f('GtkWidget'));
}

sub gtk_widget_init_template (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:insert-action-group:
=begin pod
=head2 insert-action-group

Inserts I<group> into I<widget>.

Children of I<widget> that implement [ifaceI<Gtk>.Actionable] can then be associated with actions in I<group> by setting their “action-name” to I<prefix>.`action-name`.

Note that inheritance is defined for individual actions. I.e. even if you insert a group with prefix I<prefix>, actions with the same prefix will still be inherited from the parent, unless the group contains an action with the same name.

If I<group> is C<undefined>, a previously inserted group for I<name> is removed from I<widget>.

  method insert-action-group ( Str $name, N-GObject() $group )

=item $name; the prefix for actions in I<group>
=item $group; a `GActionGroup`, or C<undefined> to remove the previously inserted group for I<name>
=end pod

method insert-action-group ( Str $name, N-GObject() $group ) {
  gtk_widget_insert_action_group( self._f('GtkWidget'), $name, $group);
}

sub gtk_widget_insert_action_group (
  N-GObject $widget, gchar-ptr $name, N-GObject $group
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:insert-after:
=begin pod
=head2 insert-after

Inserts I<widget> into the child widget list of I<parent>.

It will be placed after I<previous_sibling>, or at the beginning if I<previous_sibling> is C<undefined>.

After calling this function, `get_prev_sibling(widget)` will return I<previous_sibling>.

If I<parent> is already set as the parent widget of I<widget>, this function can also be used to reorder I<widget> in the child widget list of I<parent>.

This API is primarily meant for widget implementations; if you are just using a widget, you *must* use its own API for adding children.

  method insert-after ( N-GObject() $parent, N-GObject() $previous_sibling )

=item $parent; the parent `GtkWidget` to insert I<widget> into
=item $previous_sibling; the new previous sibling of I<widget>
=end pod

method insert-after ( N-GObject() $parent, N-GObject() $previous_sibling ) {
  gtk_widget_insert_after( self._f('GtkWidget'), $parent, $previous_sibling);
}

sub gtk_widget_insert_after (
  N-GObject $widget, N-GObject $parent, N-GObject $previous_sibling
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:insert-before:
=begin pod
=head2 insert-before

Inserts I<widget> into the child widget list of I<parent>.

It will be placed before I<next_sibling>, or at the end if I<next_sibling> is C<undefined>.

After calling this function, `get_next_sibling(widget)` will return I<next_sibling>.

If I<parent> is already set as the parent widget of I<widget>, this function can also be used to reorder I<widget> in the child widget list of I<parent>.

This API is primarily meant for widget implementations; if you are just using a widget, you *must* use its own API for adding children.

  method insert-before ( N-GObject() $parent, N-GObject() $next_sibling )

=item $parent; the parent `GtkWidget` to insert I<widget> into
=item $next_sibling; the new next sibling of I<widget>
=end pod

method insert-before ( N-GObject() $parent, N-GObject() $next_sibling ) {
  gtk_widget_insert_before( self._f('GtkWidget'), $parent, $next_sibling);
}

sub gtk_widget_insert_before (
  N-GObject $widget, N-GObject $parent, N-GObject $next_sibling
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:is-ancestor:
=begin pod
=head2 is-ancestor

Determines whether I<widget> is somewhere inside I<ancestor>, possibly with intermediate containers.

Returns: C<True> if I<ancestor> contains I<widget> as a child, grandchild, great grandchild, etc.

  method is-ancestor ( N-GObject() $ancestor --> Bool )

=item $ancestor; another `GtkWidget`
=end pod

method is-ancestor ( N-GObject() $ancestor --> Bool ) {
  gtk_widget_is_ancestor( self._f('GtkWidget'), $ancestor).Bool
}

sub gtk_widget_is_ancestor (
  N-GObject $widget, N-GObject $ancestor --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:is-drawable:
=begin pod
=head2 is-drawable

Determines whether I<widget> can be drawn to.

A widget can be drawn if it is mapped and visible.

Returns: C<True> if I<widget> is drawable, C<False> otherwise

  method is-drawable ( --> Bool )

=end pod

method is-drawable ( --> Bool ) {
  gtk_widget_is_drawable( self._f('GtkWidget')).Bool
}

sub gtk_widget_is_drawable (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:is-focus:
=begin pod
=head2 is-focus

Determines if the widget is the focus widget within its toplevel.

This does not mean that the [propertyI<Gtk>.Widget:has-focus] property is necessarily set; [propertyI<Gtk>.Widget:has-focus] will only be set if the toplevel widget additionally has the global input focus.

Returns: C<True> if the widget is the focus widget.

  method is-focus ( --> Bool )

=end pod

method is-focus ( --> Bool ) {
  gtk_widget_is_focus( self._f('GtkWidget')).Bool
}

sub gtk_widget_is_focus (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:is-sensitive:
=begin pod
=head2 is-sensitive

Returns the widget’s effective sensitivity.

This means it is sensitive itself and also its parent widget is sensitive.

Returns: C<True> if the widget is effectively sensitive

  method is-sensitive ( --> Bool )

=end pod

method is-sensitive ( --> Bool ) {
  gtk_widget_is_sensitive( self._f('GtkWidget')).Bool
}

sub gtk_widget_is_sensitive (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:is-visible:
=begin pod
=head2 is-visible

Determines whether the widget and all its parents are marked as visible.

This function does not check if the widget is obscured in any way.

See also [methodI<Gtk>.Widget.get_visible] and [methodI<Gtk>.Widget.set_visible].

Returns: C<True> if the widget and all its parents are visible

  method is-visible ( --> Bool )

=end pod

method is-visible ( --> Bool ) {
  gtk_widget_is_visible( self._f('GtkWidget')).Bool
}

sub gtk_widget_is_visible (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:keynav-failed:
=begin pod
=head2 keynav-failed

Emits the `I<keynav-failed>` signal on the widget.

This function should be called whenever keyboard navigation within a single widget hits a boundary.

The return value of this function should be interpreted in a way similar to the return value of [methodI<Gtk>.Widget.child_focus]. When C<True> is returned, stay in the widget, the failed keyboard navigation is OK and/or there is nowhere we can/should move the focus to. When C<False> is returned, the caller should continue with keyboard navigation outside the widget, e.g. by calling [methodI<Gtk>.Widget.child_focus] on the widget’s toplevel.

The default [signalI<Gtk>.WidgetI<keynav-failed>] handler returns C<False> for C<GTK_DIR_TAB_FORWARD> and C<GTK_DIR_TAB_BACKWARD>. For the other values of `GtkDirectionType` it returns C<True>.

Whenever the default handler returns C<True>, it also calls [methodI<Gtk>.Widget.error_bell] to notify the user of the failed keyboard navigation.

A use case for providing an own implementation of I<keynav-failed> (either by connecting to it or by overriding it) would be a row of [classI<Gtk>.Entry] widgets where the user should be able to navigate the entire row with the cursor keys, as e.g. known from user interfaces that require entering license keys.

Returns: C<True> if stopping keyboard navigation is fine, C<False> if the emitting widget should try to handle the keyboard navigation attempt in its parent container(s).

  method keynav-failed ( GtkDirectionType $direction --> Bool )

=item $direction; direction of focus movement
=end pod

method keynav-failed ( GtkDirectionType $direction --> Bool ) {
  gtk_widget_keynav_failed( self._f('GtkWidget'), $direction).Bool
}

sub gtk_widget_keynav_failed (
  N-GObject $widget, GEnum $direction --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:list-mnemonic-labels:
=begin pod
=head2 list-mnemonic-labels

Returns the widgets for which this widget is the target of a mnemonic.

Typically, these widgets will be labels. See, for example, [methodI<Gtk>.Label.set_mnemonic_widget]. The widgets in the list are not individually referenced. If you want to iterate through the list and perform actions involving callbacks that might destroy the widgets, you must call `g_list_foreach (result, (GFunc)g_object_ref, NULL)` first, and then unref all the widgets afterwards.

Returns: (element-type GtkWidget) (transfer container): the list of mnemonic labels; free this list with C<g_list_free()> when you are done with it.

  method list-mnemonic-labels ( --> N-GList )

=end pod

method list-mnemonic-labels ( --> N-GList ) {
  gtk_widget_list_mnemonic_labels( self._f('GtkWidget'))
}

sub gtk_widget_list_mnemonic_labels (
  N-GObject $widget --> N-GList
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:map:
=begin pod
=head2 map

Causes a widget to be mapped if it isn’t already.

This function is only for use in widget implementations.

  method map ( )

=end pod

method map ( ) {
  gtk_widget_map( self._f('GtkWidget'));
}

sub gtk_widget_map (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:measure:
=begin pod
=head2 measure



  method measure ( GtkOrientation $orientation, Int() $for_size )

=item $orientation;
=item $for_size;
=item $minimum;
=item $natural;
=item $minimum_baseline;
=item $natural_baseline;
=end pod

method measure ( GtkOrientation $orientation, Int() $for_size ) {
  gtk_widget_measure( self._f('GtkWidget'), $orientation, $for_size, my gint $minimum, my gint $natural, my gint $minimum_baseline, my gint $natural_baseline);
}

sub gtk_widget_measure (
  N-GObject $widget, GEnum $orientation, int $for_size, gint $minimum is rw, gint $natural is rw, gint $minimum_baseline is rw, gint $natural_baseline is rw
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:mnemonic-activate:
=begin pod
=head2 mnemonic-activate

Emits the I<mnemonic-activate> signal.

See [signalI<Gtk>.Widget::mnemonic-activate].

Returns: C<True> if the signal has been handled

  method mnemonic-activate ( Bool $group_cycling --> Bool )

=item $group_cycling; C<True> if there are other widgets with the same mnemonic
=end pod

method mnemonic-activate ( Bool $group_cycling --> Bool ) {
  gtk_widget_mnemonic_activate( self._f('GtkWidget'), $group_cycling).Bool
}

sub gtk_widget_mnemonic_activate (
  N-GObject $widget, gboolean $group_cycling --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:observe-children:
=begin pod
=head2 observe-children

Returns a `GListModel` to track the children of I<widget>.

Calling this function will enable extra internal bookkeeping to track children and emit signals on the returned listmodel. It may slow down operations a lot.

Applications should try hard to avoid calling this function because of the slowdowns.

Returns:  (attributes element-type=GtkWidget): a `GListModel` tracking I<widget>'s children

  method observe-children ( --> N-GList )

=end pod

method observe-children ( --> N-GList ) {
  gtk_widget_observe_children( self._f('GtkWidget'))
}

sub gtk_widget_observe_children (
  N-GObject $widget --> N-GList
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:observe-controllers:
=begin pod
=head2 observe-controllers

Returns a `GListModel` to track the [classI<Gtk>.EventController]s of I<widget>.

Calling this function will enable extra internal bookkeeping to track controllers and emit signals on the returned listmodel. It may slow down operations a lot.

Applications should try hard to avoid calling this function because of the slowdowns.

Returns:  (attributes element-type=GtkEventController): a `GListModel` tracking I<widget>'s controllers

  method observe-controllers ( --> N-GList )

=end pod

method observe-controllers ( --> N-GList ) {
  gtk_widget_observe_controllers( self._f('GtkWidget'))
}

sub gtk_widget_observe_controllers (
  N-GObject $widget --> N-GList
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:pick:
=begin pod
=head2 pick

Finds the descendant of I<widget> closest to the point (I<x>, I<y>).

The point must be given in widget coordinates, so (0, 0) is assumed to be the top left of I<widget>'s content area.

Usually widgets will return C<undefined> if the given coordinate is not contained in I<widget> checked via [methodI<Gtk>.Widget.contains]. Otherwise they will recursively try to find a child that does not return C<undefined>. Widgets are however free to customize their picking algorithm.

This function is used on the toplevel to determine the widget below the mouse cursor for purposes of hover highlighting and delivering events.

Returns: The widget descendant at the given point

  method pick ( double $x, double $y, GtkPickFlags $flags --> N-GObject )

=item $x; X coordinate to test, relative to I<widget>'s origin
=item $y; Y coordinate to test, relative to I<widget>'s origin
=item $flags; Flags to influence what is picked
=end pod

method pick ( double $x, double $y, GtkPickFlags $flags --> N-GObject ) {
  gtk_widget_pick( self._f('GtkWidget'), $x, $y, $flags)
}

sub gtk_widget_pick (
  N-GObject $widget, double $x, double $y, GtkPickFlags $flags --> N-GObject
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:queue-allocate:
=begin pod
=head2 queue-allocate

Flags the widget for a rerun of the [vfuncI<Gtk>.Widget.size_allocate] function.

Use this function instead of [methodI<Gtk>.Widget.queue_resize] when the I<widget>'s size request didn't change but it wants to reposition its contents.

An example user of this function is [methodI<Gtk>.Widget.set_halign].

This function is only for use in widget implementations.

  method queue-allocate ( )

=end pod

method queue-allocate ( ) {
  gtk_widget_queue_allocate( self._f('GtkWidget'));
}

sub gtk_widget_queue_allocate (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:queue-draw:
=begin pod
=head2 queue-draw

Schedules this widget to be redrawn in the paint phase of the current or the next frame.

This means I<widget>'s [vfuncI<Gtk>.Widget.snapshot] implementation will be called.

  method queue-draw ( )

=end pod

method queue-draw ( ) {
  gtk_widget_queue_draw( self._f('GtkWidget'));
}

sub gtk_widget_queue_draw (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:queue-resize:
=begin pod
=head2 queue-resize

Flags a widget to have its size renegotiated.

This should be called when a widget for some reason has a new size request. For example, when you change the text in a [classI<Gtk>.Label], the label queues a resize to ensure there’s enough space for the new text.

Note that you cannot call C<queue_resize()> on a widget from inside its implementation of the [vfuncI<Gtk>.Widget.size_allocate] virtual method. Calls to C<queue_resize()> from inside [vfuncI<Gtk>.Widget.size_allocate] will be silently ignored.

This function is only for use in widget implementations.

  method queue-resize ( )

=end pod

method queue-resize ( ) {
  gtk_widget_queue_resize( self._f('GtkWidget'));
}

sub gtk_widget_queue_resize (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:realize:
=begin pod
=head2 realize

Creates the GDK resources associated with a widget.

Normally realization happens implicitly; if you show a widget and all its parent containers, then the widget will be realized and mapped automatically.

Realizing a widget requires all the widget’s parent widgets to be realized; calling this function realizes the widget’s parents in addition to I<widget> itself. If a widget is not yet inside a toplevel window when you realize it, bad things will happen.

This function is primarily used in widget implementations, and isn’t very useful otherwise. Many times when you think you might need it, a better approach is to connect to a signal that will be called after the widget is realized automatically, such as [signalI<Gtk>.Widget::realize].

  method realize ( )

=end pod

method realize ( ) {
  gtk_widget_realize( self._f('GtkWidget'));
}

sub gtk_widget_realize (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:remove-controller:
=begin pod
=head2 remove-controller

Removes I<controller> from I<widget>, so that it doesn't process events anymore.

It should not be used again.

Widgets will remove all event controllers automatically when they are destroyed, there is normally no need to call this function.

  method remove-controller ( N-GObject() $controller )

=item $controller; a `GtkEventController`
=end pod

method remove-controller ( N-GObject() $controller ) {
  gtk_widget_remove_controller( self._f('GtkWidget'), $controller);
}

sub gtk_widget_remove_controller (
  N-GObject $widget, N-GObject $controller
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:remove-css-class:
=begin pod
=head2 remove-css-class

Removes a style from I<widget>.

After this, the style of I<widget> will stop matching for I<css_class>.

  method remove-css-class ( Str $css_class )

=item $css_class; The style class to remove from I<widget>, without the leading '.' used for notation of style classes
=end pod

method remove-css-class ( Str $css_class ) {
  gtk_widget_remove_css_class( self._f('GtkWidget'), $css_class);
}

sub gtk_widget_remove_css_class (
  N-GObject $widget, gchar-ptr $css_class
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:remove-mnemonic-label:
=begin pod
=head2 remove-mnemonic-label

Removes a widget from the list of mnemonic labels for this widget.

See [methodI<Gtk>.Widget.list_mnemonic_labels]. The widget must have previously been added to the list with [methodI<Gtk>.Widget.add_mnemonic_label].

  method remove-mnemonic-label ( N-GObject() $label )

=item $label; a `GtkWidget` that was previously set as a mnemonic label for I<widget> with [methodI<Gtk>.Widget.add_mnemonic_label]
=end pod

method remove-mnemonic-label ( N-GObject() $label ) {
  gtk_widget_remove_mnemonic_label( self._f('GtkWidget'), $label);
}

sub gtk_widget_remove_mnemonic_label (
  N-GObject $widget, N-GObject $label
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:remove-tick-callback:
=begin pod
=head2 remove-tick-callback

Removes a tick callback previously registered with C<add_tick_callback()>.

  method remove-tick-callback ( UInt $id )

=item $id; an id returned by [methodI<Gtk>.Widget.add_tick_callback]
=end pod

method remove-tick-callback ( UInt $id ) {
  gtk_widget_remove_tick_callback( self._f('GtkWidget'), $id);
}

sub gtk_widget_remove_tick_callback (
  N-GObject $widget, guint $id
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-can-focus:
=begin pod
=head2 set-can-focus

Specifies whether the input focus can enter the widget or any of its children.

Applications should set I<can_focus> to C<False> to mark a widget as for pointer/touch use only.

Note that having I<can_focus> be C<True> is only one of the necessary conditions for being focusable. A widget must also be sensitive and focusable and not have an ancestor that is marked as not can-focus in order to receive input focus.

See [methodI<Gtk>.Widget.grab_focus] for actually setting the input focus on a widget.

  method set-can-focus ( Bool $can_focus )

=item $can_focus; whether or not the input focus can enter the widget or any of its children
=end pod

method set-can-focus ( Bool $can_focus ) {
  gtk_widget_set_can_focus( self._f('GtkWidget'), $can_focus);
}

sub gtk_widget_set_can_focus (
  N-GObject $widget, gboolean $can_focus
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-can-target:
=begin pod
=head2 set-can-target

Sets whether I<widget> can be the target of pointer events.

  method set-can-target ( Bool $can_target )

=item $can_target; whether this widget should be able to receive pointer events
=end pod

method set-can-target ( Bool $can_target ) {
  gtk_widget_set_can_target( self._f('GtkWidget'), $can_target);
}

sub gtk_widget_set_can_target (
  N-GObject $widget, gboolean $can_target
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-child-visible:
=begin pod
=head2 set-child-visible

Sets whether I<widget> should be mapped along with its parent.

The child visibility can be set for widget before it is added to a container with [methodI<Gtk>.Widget.set_parent], to avoid mapping children unnecessary before immediately unmapping them. However it will be reset to its default state of C<True> when the widget is removed from a container.

Note that changing the child visibility of a widget does not queue a resize on the widget. Most of the time, the size of a widget is computed from all visible children, whether or not they are mapped. If this is not the case, the container can queue a resize itself.

This function is only useful for container implementations and should never be called by an application.

  method set-child-visible ( Bool $child_visible )

=item $child_visible; if C<True>, I<widget> should be mapped along with its parent.
=end pod

method set-child-visible ( Bool $child_visible ) {
  gtk_widget_set_child_visible( self._f('GtkWidget'), $child_visible);
}

sub gtk_widget_set_child_visible (
  N-GObject $widget, gboolean $child_visible
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-css-classes:
=begin pod
=head2 set-css-classes

Clear all style classes applied to I<widget> and replace them with I<classes>.

  method set-css-classes ( CArray[Str] $classes )

=item $classes; C<undefined>-terminated list of style classes to apply to I<widget>.
=end pod

method set-css-classes ( CArray[Str] $classes ) {
  gtk_widget_set_css_classes( self._f('GtkWidget'), $classes);
}

sub gtk_widget_set_css_classes (
  N-GObject $widget, gchar-pptr $classes
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-cursor:
=begin pod
=head2 set-cursor

Sets the cursor to be shown when pointer devices point towards I<widget>.

If the I<cursor> is NULL, I<widget> will use the cursor inherited from the parent widget.

  method set-cursor ( N-GObject() $cursor )

=item $cursor; the new cursor
=end pod

method set-cursor ( N-GObject() $cursor ) {
  gtk_widget_set_cursor( self._f('GtkWidget'), $cursor);
}

sub gtk_widget_set_cursor (
  N-GObject $widget, N-GObject $cursor
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-cursor-from-name:
=begin pod
=head2 set-cursor-from-name

Sets a named cursor to be shown when pointer devices point towards I<widget>.

This is a utility function that creates a cursor via [ctorI<Gdk>.Cursor.new_from_name] and then sets it on I<widget> with [methodI<Gtk>.Widget.set_cursor]. See those functions for details.

On top of that, this function allows I<name> to be C<undefined>, which will do the same as calling [methodI<Gtk>.Widget.set_cursor] with a C<undefined> cursor.

  method set-cursor-from-name ( Str $name )

=item $name; The name of the cursor
=end pod

method set-cursor-from-name ( Str $name ) {
  gtk_widget_set_cursor_from_name( self._f('GtkWidget'), $name);
}

sub gtk_widget_set_cursor_from_name (
  N-GObject $widget, gchar-ptr $name
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-default-direction:
=begin pod
=head2 set-default-direction

Sets the default reading direction for widgets.

See [methodI<Gtk>.Widget.set_direction].

  method set-default-direction ( GtkTextDirection $dir )

=item $dir; the new default direction. This cannot be C<GTK_TEXT_DIR_NONE>.
=end pod

method set-default-direction ( GtkTextDirection $dir ) {
  gtk_widget_set_default_direction( self._f('GtkWidget'), $dir);
}

sub gtk_widget_set_default_direction (
  GEnum $dir
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-direction:
=begin pod
=head2 set-direction

Sets the reading direction on a particular widget.

This direction controls the primary direction for widgets containing text, and also the direction in which the children of a container are packed. The ability to set the direction is present in order so that correct localization into languages with right-to-left reading directions can be done. Generally, applications will let the default reading direction present, except for containers where the containers are arranged in an order that is explicitly visual rather than logical (such as buttons for text justification).

If the direction is set to C<GTK_TEXT_DIR_NONE>, then the value set by [funcI<Gtk>.Widget.set_default_direction] will be used.

  method set-direction ( GtkTextDirection $dir )

=item $dir; the new direction
=end pod

method set-direction ( GtkTextDirection $dir ) {
  gtk_widget_set_direction( self._f('GtkWidget'), $dir);
}

sub gtk_widget_set_direction (
  N-GObject $widget, GEnum $dir
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-focus-child:
=begin pod
=head2 set-focus-child

Set I<child> as the current focus child of I<widget>.

This function is only suitable for widget implementations. If you want a certain widget to get the input focus, call [methodI<Gtk>.Widget.grab_focus] on it.

  method set-focus-child ( N-GObject() $child )

=item $child; a direct child widget of I<widget> or C<undefined> to unset the focus child of I<widget>
=end pod

method set-focus-child ( N-GObject() $child ) {
  gtk_widget_set_focus_child( self._f('GtkWidget'), $child);
}

sub gtk_widget_set_focus_child (
  N-GObject $widget, N-GObject $child
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-focus-on-click:
=begin pod
=head2 set-focus-on-click

Sets whether the widget should grab focus when it is clicked with the mouse.

Making mouse clicks not grab focus is useful in places like toolbars where you don’t want the keyboard focus removed from the main area of the application.

  method set-focus-on-click ( Bool $focus_on_click )

=item $focus_on_click; whether the widget should grab focus when clicked with the mouse
=end pod

method set-focus-on-click ( Bool $focus_on_click ) {
  gtk_widget_set_focus_on_click( self._f('GtkWidget'), $focus_on_click);
}

sub gtk_widget_set_focus_on_click (
  N-GObject $widget, gboolean $focus_on_click
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-focusable:
=begin pod
=head2 set-focusable

Specifies whether I<widget> can own the input focus.

Widget implementations should set I<focusable> to C<True> in their C<init()> function if they want to receive keyboard input.

Note that having I<focusable> be C<True> is only one of the necessary conditions for being focusable. A widget must also be sensitive and can-focus and not have an ancestor that is marked as not can-focus in order to receive input focus.

See [methodI<Gtk>.Widget.grab_focus] for actually setting the input focus on a widget.

  method set-focusable ( Bool $focusable )

=item $focusable; whether or not I<widget> can own the input focus
=end pod

method set-focusable ( Bool $focusable ) {
  gtk_widget_set_focusable( self._f('GtkWidget'), $focusable);
}

sub gtk_widget_set_focusable (
  N-GObject $widget, gboolean $focusable
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-font-map:
=begin pod
=head2 set-font-map

Sets the font map to use for Pango rendering.

The font map is the object that is used to look up fonts. Setting a custom font map can be useful in special situations, e.g. when you need to add application-specific fonts to the set of available fonts.

When not set, the widget will inherit the font map from its parent.

  method set-font-map ( N-GObject() $font_map )

=item $font_map; a `PangoFontMap`, or C<undefined> to unset any previously set font map
=end pod

method set-font-map ( N-GObject() $font_map ) {
  gtk_widget_set_font_map( self._f('GtkWidget'), $font_map);
}

sub gtk_widget_set_font_map (
  N-GObject $widget, N-GObject $font_map
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-font-options:
=begin pod
=head2 set-font-options

Sets the `cairo_font_options_t` used for Pango rendering in this widget.

When not set, the default font options for the `GdkDisplay` will be used.

  method set-font-options ( cairo_font_options_t $options )

=item $options; a `cairo_font_options_t` to unset any previously set default font options
=end pod

method set-font-options ( cairo_font_options_t $options ) {
  gtk_widget_set_font_options( self._f('GtkWidget'), $options);
}

sub gtk_widget_set_font_options (
  N-GObject $widget, cairo_font_options_t $options
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-halign:
=begin pod
=head2 set-halign

Sets the horizontal alignment of I<widget>.

  method set-halign ( GtkAlign $align )

=item $align; the horizontal alignment
=end pod

method set-halign ( GtkAlign $align ) {
  gtk_widget_set_halign( self._f('GtkWidget'), $align);
}

sub gtk_widget_set_halign (
  N-GObject $widget, GEnum $align
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-has-tooltip:
=begin pod
=head2 set-has-tooltip

Sets the `has-tooltip` property on I<widget> to I<has_tooltip>.

  method set-has-tooltip ( Bool $has_tooltip )

=item $has_tooltip; whether or not I<widget> has a tooltip.
=end pod

method set-has-tooltip ( Bool $has_tooltip ) {
  gtk_widget_set_has_tooltip( self._f('GtkWidget'), $has_tooltip);
}

sub gtk_widget_set_has_tooltip (
  N-GObject $widget, gboolean $has_tooltip
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-hexpand:
=begin pod
=head2 set-hexpand

Sets whether the widget would like any available extra horizontal space.

When a user resizes a `GtkWindow`, widgets with expand=TRUE generally receive the extra space. For example, a list or scrollable area or document in your window would often be set to expand.

Call this function to set the expand flag if you would like your widget to become larger horizontally when the window has extra room.

By default, widgets automatically expand if any of their children want to expand. (To see if a widget will automatically expand given its current children and state, call [methodI<Gtk>.Widget.compute_expand]. A container can decide how the expandability of children affects the expansion of the container by overriding the compute_expand virtual method on `GtkWidget`.).

Setting hexpand explicitly with this function will override the automatic expand behavior.

This function forces the widget to expand or not to expand, regardless of children. The override occurs because [methodI<Gtk>.Widget.set_hexpand] sets the hexpand-set property (see [methodI<Gtk>.Widget.set_hexpand_set]) which causes the widget’s hexpand value to be used, rather than looking at children and widget state.

  method set-hexpand ( Bool $expand )

=item $expand; whether to expand
=end pod

method set-hexpand ( Bool $expand ) {
  gtk_widget_set_hexpand( self._f('GtkWidget'), $expand);
}

sub gtk_widget_set_hexpand (
  N-GObject $widget, gboolean $expand
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-hexpand-set:
=begin pod
=head2 set-hexpand-set

Sets whether the hexpand flag will be used.

The [propertyI<Gtk>.Widget:hexpand-set] property will be set automatically when you call [methodI<Gtk>.Widget.set_hexpand] to set hexpand, so the most likely reason to use this function would be to unset an explicit expand flag.

If hexpand is set, then it overrides any computed expand value based on child widgets. If hexpand is not set, then the expand value depends on whether any children of the widget would like to expand.

There are few reasons to use this function, but it’s here for completeness and consistency.

  method set-hexpand-set ( Bool $set )

=item $set; value for hexpand-set property
=end pod

method set-hexpand-set ( Bool $set ) {
  gtk_widget_set_hexpand_set( self._f('GtkWidget'), $set);
}

sub gtk_widget_set_hexpand_set (
  N-GObject $widget, gboolean $set
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-layout-manager:
=begin pod
=head2 set-layout-manager

Sets the layout manager delegate instance that provides an implementation for measuring and allocating the children of I<widget>.

  method set-layout-manager ( GtkLayoutManager $layout_manager )

=item $layout_manager; a `GtkLayoutManager`
=end pod

method set-layout-manager ( GtkLayoutManager $layout_manager ) {
  gtk_widget_set_layout_manager( self._f('GtkWidget'), $layout_manager);
}

sub gtk_widget_set_layout_manager (
  N-GObject $widget, GtkLayoutManager $layout_manager
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-margin-bottom:
=begin pod
=head2 set-margin-bottom

Sets the bottom margin of I<widget>.

  method set-margin-bottom ( Int() $margin )

=item $margin; the bottom margin
=end pod

method set-margin-bottom ( Int() $margin ) {
  gtk_widget_set_margin_bottom( self._f('GtkWidget'), $margin);
}

sub gtk_widget_set_margin_bottom (
  N-GObject $widget, int $margin
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-margin-end:
=begin pod
=head2 set-margin-end

Sets the end margin of I<widget>.

  method set-margin-end ( Int() $margin )

=item $margin; the end margin
=end pod

method set-margin-end ( Int() $margin ) {
  gtk_widget_set_margin_end( self._f('GtkWidget'), $margin);
}

sub gtk_widget_set_margin_end (
  N-GObject $widget, int $margin
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-margin-start:
=begin pod
=head2 set-margin-start

Sets the start margin of I<widget>.

  method set-margin-start ( Int() $margin )

=item $margin; the start margin
=end pod

method set-margin-start ( Int() $margin ) {
  gtk_widget_set_margin_start( self._f('GtkWidget'), $margin);
}

sub gtk_widget_set_margin_start (
  N-GObject $widget, int $margin
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-margin-top:
=begin pod
=head2 set-margin-top

Sets the top margin of I<widget>.

  method set-margin-top ( Int() $margin )

=item $margin; the top margin
=end pod

method set-margin-top ( Int() $margin ) {
  gtk_widget_set_margin_top( self._f('GtkWidget'), $margin);
}

sub gtk_widget_set_margin_top (
  N-GObject $widget, int $margin
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-name:
=begin pod
=head2 set-name

Sets a widgets name.

Setting a name allows you to refer to the widget from a CSS file. You can apply a style to widgets with a particular name in the CSS file. See the documentation for the CSS syntax (on the same page as the docs for [classI<Gtk>.StyleContext].

Note that the CSS syntax has certain special characters to delimit and represent elements in a selector (period, #, >, *...), so using these will make your widget impossible to match by name. Any combination of alphanumeric symbols, dashes and underscores will suffice.

  method set-name ( Str $name )

=item $name; name for the widget
=end pod

method set-name ( Str $name ) {
  gtk_widget_set_name( self._f('GtkWidget'), $name);
}

sub gtk_widget_set_name (
  N-GObject $widget, gchar-ptr $name
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-opacity:
=begin pod
=head2 set-opacity

Request the I<widget> to be rendered partially transparent.

An opacity of 0 is fully transparent and an opacity of 1 is fully opaque.

Opacity works on both toplevel widgets and child widgets, although there are some limitations: For toplevel widgets, applying opacity depends on the capabilities of the windowing system. On X11, this has any effect only on X displays with a compositing manager, see C<gdk_display_is_composited()>. On Windows and Wayland it should always work, although setting a window’s opacity after the window has been shown may cause some flicker.

Note that the opacity is inherited through inclusion — if you set a toplevel to be partially translucent, all of its content will appear translucent, since it is ultimatively rendered on that toplevel. The opacity value itself is not inherited by child widgets (since that would make widgets deeper in the hierarchy progressively more translucent). As a consequence, [classI<Gtk>.Popover]s and other [ifaceI<Gtk>.Native] widgets with their own surface will use their own opacity value, and thus by default appear non-translucent, even if they are attached to a toplevel that is translucent.

  method set-opacity ( double $opacity )

=item $opacity; desired opacity, between 0 and 1
=end pod

method set-opacity ( double $opacity ) {
  gtk_widget_set_opacity( self._f('GtkWidget'), $opacity);
}

sub gtk_widget_set_opacity (
  N-GObject $widget, double $opacity
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-overflow:
=begin pod
=head2 set-overflow

Sets how I<widget> treats content that is drawn outside the widget's content area.

See the definition of [enumI<Gtk>.Overflow] for details.

This setting is provided for widget implementations and should not be used by application code.

The default value is C<GTK_OVERFLOW_VISIBLE>.

  method set-overflow ( GtkOverflow $overflow )

=item $overflow; desired overflow
=end pod

method set-overflow ( GtkOverflow $overflow ) {
  gtk_widget_set_overflow( self._f('GtkWidget'), $overflow);
}

sub gtk_widget_set_overflow (
  N-GObject $widget, GtkOverflow $overflow
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-parent:
=begin pod
=head2 set-parent

Sets I<parent> as the parent widget of I<widget>.

This takes care of details such as updating the state and style of the child to reflect its new location and resizing the parent. The opposite function is [methodI<Gtk>.Widget.unparent].

This function is useful only when implementing subclasses of `GtkWidget`.

  method set-parent ( N-GObject() $parent )

=item $parent; parent widget
=end pod

method set-parent ( N-GObject() $parent ) {
  gtk_widget_set_parent( self._f('GtkWidget'), $parent);
}

sub gtk_widget_set_parent (
  N-GObject $widget, N-GObject $parent
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-receives-default:
=begin pod
=head2 set-receives-default

Specifies whether I<widget> will be treated as the default widget within its toplevel when it has the focus, even if another widget is the default.

  method set-receives-default ( Bool $receives_default )

=item $receives_default; whether or not I<widget> can be a default widget.
=end pod

method set-receives-default ( Bool $receives_default ) {
  gtk_widget_set_receives_default( self._f('GtkWidget'), $receives_default);
}

sub gtk_widget_set_receives_default (
  N-GObject $widget, gboolean $receives_default
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-sensitive:
=begin pod
=head2 set-sensitive

Sets the sensitivity of a widget.

A widget is sensitive if the user can interact with it. Insensitive widgets are “grayed out” and the user can’t interact with them. Insensitive widgets are known as “inactive”, “disabled”, or “ghosted” in some other toolkits.

  method set-sensitive ( Bool $sensitive )

=item $sensitive; C<True> to make the widget sensitive
=end pod

method set-sensitive ( Bool $sensitive ) {
  gtk_widget_set_sensitive( self._f('GtkWidget'), $sensitive);
}

sub gtk_widget_set_sensitive (
  N-GObject $widget, gboolean $sensitive
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-size-request:
=begin pod
=head2 set-size-request

Sets the minimum size of a widget.

That is, the widget’s size request will be at least I<width> by I<height>. You can use this function to force a widget to be larger than it normally would be.

In most cases, [methodI<Gtk>.Window.set_default_size] is a better choice for toplevel windows than this function; setting the default size will still allow users to shrink the window. Setting the size request will force them to leave the window at least as large as the size request.

Note the inherent danger of setting any fixed size - themes, translations into other languages, different fonts, and user action can all change the appropriate size for a given widget. So, it's basically impossible to hardcode a size that will always be correct.

The size request of a widget is the smallest size a widget can accept while still functioning well and drawing itself correctly. However in some strange cases a widget may be allocated less than its requested size, and in many cases a widget may be allocated more space than it requested.

If the size request in a given direction is -1 (unset), then the “natural” size request of the widget will be used instead.

The size request set here does not include any margin from the properties [propertyI<Gtk>.Widget:margin-start], [propertyI<Gtk>.Widget:margin-end], [propertyI<Gtk>.Widget:margin-top], and [propertyI<Gtk>.Widget:margin-bottom], but it does include pretty much all other padding or border properties set by any subclass of `GtkWidget`.

  method set-size-request ( Int() $width, Int() $height )

=item $width; width I<widget> should request, or -1 to unset
=item $height; height I<widget> should request, or -1 to unset
=end pod

method set-size-request ( Int() $width, Int() $height ) {
  gtk_widget_set_size_request( self._f('GtkWidget'), $width, $height);
}

sub gtk_widget_set_size_request (
  N-GObject $widget, int $width, int $height
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-state-flags:
=begin pod
=head2 set-state-flags

Turns on flag values in the current widget state.

Typical widget states are insensitive, prelighted, etc.

This function accepts the values C<GTK_STATE_FLAG_DIR_LTR> and C<GTK_STATE_FLAG_DIR_RTL> but ignores them. If you want to set the widget's direction, use [methodI<Gtk>.Widget.set_direction].

This function is for use in widget implementations.

  method set-state-flags ( GtkStateFlags $flags, Bool $clear )

=item $flags; State flags to turn on
=item $clear; Whether to clear state before turning on I<flags>
=end pod

method set-state-flags ( GtkStateFlags $flags, Bool $clear ) {
  gtk_widget_set_state_flags( self._f('GtkWidget'), $flags, $clear);
}

sub gtk_widget_set_state_flags (
  N-GObject $widget, GEnum $flags, gboolean $clear
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-tooltip-markup:
=begin pod
=head2 set-tooltip-markup

Sets I<markup> as the contents of the tooltip, which is marked up with Pango markup.

This function will take care of setting the [propertyI<Gtk>.Widget:has-tooltip] as a side effect, and of the default handler for the [signalI<Gtk>.Widget::query-tooltip] signal.

See also [methodI<Gtk>.Tooltip.set_markup].

  method set-tooltip-markup ( Str $markup )

=item $markup; the contents of the tooltip for I<widget>
=end pod

method set-tooltip-markup ( Str $markup ) {
  gtk_widget_set_tooltip_markup( self._f('GtkWidget'), $markup);
}

sub gtk_widget_set_tooltip_markup (
  N-GObject $widget, gchar-ptr $markup
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-tooltip-text:
=begin pod
=head2 set-tooltip-text

Sets I<text> as the contents of the tooltip.

If I<text> contains any markup, it will be escaped.

This function will take care of setting [propertyI<Gtk>.Widget:has-tooltip] as a side effect, and of the default handler for the [signalI<Gtk>.Widget::query-tooltip] signal.

See also [methodI<Gtk>.Tooltip.set_text].

  method set-tooltip-text ( Str $text )

=item $text; the contents of the tooltip for I<widget>
=end pod

method set-tooltip-text ( Str $text ) {
  gtk_widget_set_tooltip_text( self._f('GtkWidget'), $text);
}

sub gtk_widget_set_tooltip_text (
  N-GObject $widget, gchar-ptr $text
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-valign:
=begin pod
=head2 set-valign

Sets the vertical alignment of I<widget>.

  method set-valign ( GtkAlign $align )

=item $align; the vertical alignment
=end pod

method set-valign ( GtkAlign $align ) {
  gtk_widget_set_valign( self._f('GtkWidget'), $align);
}

sub gtk_widget_set_valign (
  N-GObject $widget, GEnum $align
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-vexpand:
=begin pod
=head2 set-vexpand

Sets whether the widget would like any available extra vertical space.

See [methodI<Gtk>.Widget.set_hexpand] for more detail.

  method set-vexpand ( Bool $expand )

=item $expand; whether to expand
=end pod

method set-vexpand ( Bool $expand ) {
  gtk_widget_set_vexpand( self._f('GtkWidget'), $expand);
}

sub gtk_widget_set_vexpand (
  N-GObject $widget, gboolean $expand
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-vexpand-set:
=begin pod
=head2 set-vexpand-set

Sets whether the vexpand flag will be used.

See [methodI<Gtk>.Widget.set_hexpand_set] for more detail.

  method set-vexpand-set ( Bool $set )

=item $set; value for vexpand-set property
=end pod

method set-vexpand-set ( Bool $set ) {
  gtk_widget_set_vexpand_set( self._f('GtkWidget'), $set);
}

sub gtk_widget_set_vexpand_set (
  N-GObject $widget, gboolean $set
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:set-visible:
=begin pod
=head2 set-visible

Sets the visibility state of I<widget>.

Note that setting this to C<True> doesn’t mean the widget is actually viewable, see [methodI<Gtk>.Widget.get_visible].

This function simply calls [methodI<Gtk>.Widget.show] or [methodI<Gtk>.Widget.hide] but is nicer to use when the visibility of the widget depends on some condition.

  method set-visible ( Bool $visible )

=item $visible; whether the widget should be shown or not
=end pod

method set-visible ( Bool $visible ) {
  gtk_widget_set_visible( self._f('GtkWidget'), $visible);
}

sub gtk_widget_set_visible (
  N-GObject $widget, gboolean $visible
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:should-layout:
=begin pod
=head2 should-layout

Returns whether I<widget> should contribute to the measuring and allocation of its parent.

This is C<False> for invisible children, but also for children that have their own surface.

Returns: C<True> if child should be included in measuring and allocating

  method should-layout ( --> Bool )

=end pod

method should-layout ( --> Bool ) {
  gtk_widget_should_layout( self._f('GtkWidget')).Bool
}

sub gtk_widget_should_layout (
  N-GObject $widget --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:show:
=begin pod
=head2 show

Flags a widget to be displayed.

Any widget that isn’t shown will not appear on the screen.

Remember that you have to show the containers containing a widget, in addition to the widget itself, before it will appear onscreen.

When a toplevel container is shown, it is immediately realized and mapped; other shown widgets are realized and mapped when their toplevel container is realized and mapped.

  method show ( )

=end pod

method show ( ) {
  gtk_widget_show( self._f('GtkWidget'));
}

sub gtk_widget_show (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:size-allocate:
=begin pod
=head2 size-allocate

Allocates widget with a transformation that translates the origin to the position in I<allocation>.

This is a simple form of [methodI<Gtk>.Widget.allocate].

  method size-allocate ( GtkAllocation $allocation, Int() $baseline )

=item $allocation; position and size to be allocated to I<widget>
=item $baseline; The baseline of the child, or -1
=end pod

method size-allocate ( GtkAllocation $allocation, Int() $baseline ) {
  gtk_widget_size_allocate( self._f('GtkWidget'), $allocation, $baseline);
}

sub gtk_widget_size_allocate (
  N-GObject $widget, GtkAllocation $allocation, int $baseline
) is native(&gtk4-lib)
  { * }
}}
#-------------------------------------------------------------------------------
#TM:0:snapshot-child:
=begin pod
=head2 snapshot-child

Snapshot the a child of I<widget>.

When a widget receives a call to the snapshot function, it must send synthetic [vfuncI<Gtk>.Widget.snapshot] calls to all children. This function provides a convenient way of doing this. A widget, when it receives a call to its [vfuncI<Gtk>.Widget.snapshot] function, calls C<snapshot_child()> once for each child, passing in the I<snapshot> the widget received.

C<snapshot_child()> takes care of translating the origin of I<snapshot>, and deciding whether the child needs to be snapshot.

This function does nothing for children that implement `GtkNative`.

  method snapshot-child ( N-GObject() $child, GtkSnapshot $snapshot )

=item $child; a child of I<widget>
=item $snapshot; `GtkSnapshot` as passed to the widget. In particular, no calls to C<gtk_snapshot_translate()> or other transform calls should have been made.
=end pod

method snapshot-child ( N-GObject() $child, GtkSnapshot $snapshot ) {
  gtk_widget_snapshot_child( self._f('GtkWidget'), $child, $snapshot);
}

sub gtk_widget_snapshot_child (
  N-GObject $widget, N-GObject $child, GtkSnapshot $snapshot
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:translate-coordinates:
=begin pod
=head2 translate-coordinates

Translate coordinates relative to I<src_widget>’s allocation to coordinates relative to I<dest_widget>’s allocations.

In order to perform this operation, both widget must share a common ancestor.

Returns: C<False> if I<src_widget> and I<dest_widget> have no common ancestor. In this case, 0 is stored in *I<dest_x> and *I<dest_y>. Otherwise C<True>.

  method translate-coordinates ( N-GObject() $dest_widget, double $src_x, double $src_y, double $dest_x, double $dest_y --> Bool )

=item $dest_widget; a `GtkWidget`
=item $src_x; X position relative to I<src_widget>
=item $src_y; Y position relative to I<src_widget>
=item $dest_x; location to store X position relative to I<dest_widget>
=item $dest_y; location to store Y position relative to I<dest_widget>
=end pod

method translate-coordinates ( N-GObject() $dest_widget, double $src_x, double $src_y, double $dest_x, double $dest_y --> Bool ) {
  gtk_widget_translate_coordinates( self._f('GtkWidget'), $dest_widget, $src_x, $src_y, $dest_x, $dest_y).Bool
}

sub gtk_widget_translate_coordinates (
  N-GObject $src_widget, N-GObject $dest_widget, double $src_x, double $src_y, double $dest_x, double $dest_y --> gboolean
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:trigger-tooltip-query:
=begin pod
=head2 trigger-tooltip-query

Triggers a tooltip query on the display where the toplevel of I<widget> is located.

  method trigger-tooltip-query ( )

=end pod

method trigger-tooltip-query ( ) {
  gtk_widget_trigger_tooltip_query( self._f('GtkWidget'));
}

sub gtk_widget_trigger_tooltip_query (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:unmap:
=begin pod
=head2 unmap

Causes a widget to be unmapped if it’s currently mapped.

This function is only for use in widget implementations.

  method unmap ( )

=end pod

method unmap ( ) {
  gtk_widget_unmap( self._f('GtkWidget'));
}

sub gtk_widget_unmap (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:unparent:
=begin pod
=head2 unparent

Dissociate I<widget> from its parent.

This function is only for use in widget implementations, typically in dispose.

  method unparent ( )

=end pod

method unparent ( ) {
  gtk_widget_unparent( self._f('GtkWidget'));
}

sub gtk_widget_unparent (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:unrealize:
=begin pod
=head2 unrealize

Causes a widget to be unrealized (frees all GDK resources associated with the widget).

This function is only useful in widget implementations.

  method unrealize ( )

=end pod

method unrealize ( ) {
  gtk_widget_unrealize( self._f('GtkWidget'));
}

sub gtk_widget_unrealize (
  N-GObject $widget
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:unset-state-flags:
=begin pod
=head2 unset-state-flags

Turns off flag values for the current widget state.

See [methodI<Gtk>.Widget.set_state_flags].

This function is for use in widget implementations.

  method unset-state-flags ( GtkStateFlags $flags )

=item $flags; State flags to turn off
=end pod

method unset-state-flags ( GtkStateFlags $flags ) {
  gtk_widget_unset_state_flags( self._f('GtkWidget'), $flags);
}

sub gtk_widget_unset_state_flags (
  N-GObject $widget, GEnum $flags
) is native(&gtk4-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head1 Signals


=comment -----------------------------------------------------------------------
=comment #TS:0:destroy:
=head2 destroy

Signals that all holders of a reference to the widget should release
the reference that they hold.

May result in finalization of the widget if all references are released.

This signal is not suitable for saving widget state.

  method handler (
    Gnome::Gtk4::Widget :_widget($object),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $object; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:direction-changed:
=head2 direction-changed

Emitted when the text direction of a widget changes.

  method handler (
    Unknown type: GTK_TYPE_TEXT_DIRECTION $previous_direction,
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $previous_direction; the previous text direction of I<widget>
=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:hide:
=head2 hide

Emitted when I<widget> is hidden.

  method handler (
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:keynav-failed:
=head2 keynav-failed

Emitted if keyboard navigation fails.

See [methodI<Gtk>.Widget.keynav_failed] for details.

Returns: C<True> if stopping keyboard navigation is fine, C<False>
if the emitting widget should try to handle the keyboard
navigation attempt in its parent widget(s).

  method handler (
    Unknown type: GTK_TYPE_DIRECTION_TYPE $direction,
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options

    --> Bool
  )

=item $direction; the direction of movement
=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:map:
=head2 map

Emitted when I<widget> is going to be mapped.

A widget is mapped when the widget is visible (which is controlled with
[propertyI<Gtk>.Widget:visible]) and all its parents up to the toplevel widget
are also visible.

The I<map> signal can be used to determine whether a widget will be drawn,
for instance it can resume an animation that was stopped during the
emission of [signalI<Gtk>.Widget::unmap].

  method handler (
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:mnemonic-activate:
=head2 mnemonic-activate

Emitted when a widget is activated via a mnemonic.

The default handler for this signal activates I<widget> if I<group_cycling>
is C<False>, or just makes I<widget> grab focus if I<group_cycling> is C<True>.

Returns: C<True> to stop other handlers from being invoked for the event.
C<False> to propagate the event further.

  method handler (
    Bool $group_cycling,
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options

    --> Bool
  )

=item $group_cycling; C<True> if there are other widgets with the same mnemonic
=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:move-focus:
=head2 move-focus

Emitted when the focus is moved.

  method handler (
    Unknown type: GTK_TYPE_DIRECTION_TYPE $direction,
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $direction; the direction of the focus move
=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:query-tooltip:
=head2 query-tooltip

Emitted when the widgets tooltip is about to be shown.

This happens when the [propertyI<Gtk>.Widget:has-tooltip] property
is C<True> and the hover timeout has expired with the cursor hovering
"above" I<widget>; or emitted when I<widget> got focus in keyboard mode.

Using the given coordinates, the signal handler should determine
whether a tooltip should be shown for I<widget>. If this is the case
C<True> should be returned, C<False> otherwise.  Note that if
I<keyboard_mode> is C<True>, the values of I<x> and I<y> are undefined and
should not be used.

The signal handler is free to manipulate I<tooltip> with the therefore
destined function calls.

Returns: C<True> if I<tooltip> should be shown right now, C<False> otherwise.

  method handler (
    Int $x,
    Int $y,
    Bool $keyboard_mode,
    Unknown type: GTK_TYPE_TOOLTIP $tooltip,
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options

    --> Bool
  )

=item $x; the x coordinate of the cursor position where the request has been emitted, relative to I<widget>'s left side
=item $y; the y coordinate of the cursor position where the request has been emitted, relative to I<widget>'s top
=item $keyboard_mode; C<True> if the tooltip was triggered using the keyboard
=item $tooltip; a `GtkTooltip`
=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:realize:
=head2 realize

Emitted when I<widget> is associated with a `GdkSurface`.

This means that [methodI<Gtk>.Widget.realize] has been called
or the widget has been mapped (that is, it is going to be drawn).

  method handler (
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:show:
=head2 show

Emitted when I<widget> is shown.

  method handler (
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:state-flags-changed:
=head2 state-flags-changed

Emitted when the widget state changes.

See [methodI<Gtk>.Widget.get_state_flags].

  method handler (
    Unknown type: GTK_TYPE_STATE_FLAGS $flags,
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $flags; The previous state flags.
=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:unmap:
=head2 unmap

Emitted when I<widget> is going to be unmapped.

A widget is unmapped when either it or any of its parents up to the
toplevel widget have been set as hidden.

As I<unmap> indicates that a widget will not be shown any longer,
it can be used to, for example, stop an animation on the widget.

  method handler (
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=comment -----------------------------------------------------------------------
=comment #TS:0:unrealize:
=head2 unrealize

Emitted when the `GdkSurface` associated with I<widget> is destroyed.

This means that [methodI<Gtk>.Widget.unrealize] has been called
or the widget has been unmapped (that is, it is going to be hidden).

  method handler (
    Gnome::Gtk4::Widget :_widget($widget),
    Int :$_handler-id,
    N-GObject :$_native-object,
    *%user-options
  )

=item $widget; The instance which registered the signal
=item $_handler-id; The handler id which is returned from the registration
=item $_native-object; The native object provided by the caller wrapped in the Raku object.
=item %user-options; A list of named arguments provided at the C<register-signal()> method

=end pod

#-------------------------------------------------------------------------------
=begin pod
=head1 Properties

=comment -----------------------------------------------------------------------
=comment #TP:0:can-focus:
=head2 can-focus

Whether the widget or any of its descendents can accept
the input focus.

This property is meant to be set by widget implementations,
typically in their instance init function.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is TRUE.


=comment -----------------------------------------------------------------------
=comment #TP:0:can-target:
=head2 can-target

Whether the widget can receive pointer events.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is TRUE.


=comment -----------------------------------------------------------------------
=comment #TP:0:css-classes:
=head2 css-classes

A list of css classes applied to this widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOXED
=item The type of this G_TYPE_BOXED object is G_TYPE_STRV
=item Parameter is readable and writable.


=comment -----------------------------------------------------------------------
=comment #TP:0:css-name:
=head2 css-name

The name of this widget in the CSS tree.

This property is meant to be set by widget implementations,
typically in their instance init function.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_STRING
=item Parameter is readable and writable.
=item Parameter is set on construction of object.
=item Default value is undefined.


=comment -----------------------------------------------------------------------
=comment #TP:0:cursor:
=head2 cursor
The cursor to show when hovering above widget

=item B<Gnome::GObject::Value> type of this property is G_TYPE_OBJECT
=item The type of this G_TYPE_OBJECT object is GDK_TYPE_CURSOR
=item Parameter is readable and writable.


=comment -----------------------------------------------------------------------
=comment #TP:0:focus-on-click:
=head2 focus-on-click

Whether the widget should grab focus when it is clicked with the mouse.

This property is only relevant for widgets that can take focus.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is TRUE.


=comment -----------------------------------------------------------------------
=comment #TP:0:focusable:
=head2 focusable

Whether this widget itself will accept the input focus.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:halign:
=head2 halign

How to distribute horizontal space if widget gets extra space.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_ENUM
=item The type of this G_TYPE_ENUM object is GTK_TYPE_ALIGN
=item Parameter is readable and writable.
=item Default value is GTK_ALIGN_FILL.


=comment -----------------------------------------------------------------------
=comment #TP:0:has-default:
=head2 has-default

Whether the widget is the default widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:has-focus:
=head2 has-focus

Whether the widget has the input focus.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:has-tooltip:
=head2 has-tooltip

Enables or disables the emission of the I<query-tooltip> signal on @widget.

A value of %TRUE indicates that @widget can have a tooltip, in this case
the widget will be queried using [signal@Gtk.Widget::query-tooltip] to
determine whether it will provide a tooltip or not.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:hexpand:
=head2 hexpand
Whether widget wants more horizontal space

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:hexpand-set:
=head2 hexpand-set

Whether to use the `hexpand` property.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:layout-manager:
=head2 layout-manager

The `GtkLayoutManager` instance to use to compute the preferred size
of the widget, and allocate its children.

This property is meant to be set by widget implementations,
typically in their instance init function.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_OBJECT
=item The type of this G_TYPE_OBJECT object is GTK_TYPE_LAYOUT_MANAGER
=item Parameter is readable and writable.


=comment -----------------------------------------------------------------------
=comment #TP:0:margin-bottom:
=head2 margin-bottom

Margin on bottom side of widget.

This property adds margin outside of the widget's normal size
request, the margin will be added in addition to the size from
C<.set-size-request()> for example.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_INT
=item Parameter is readable and writable.
=item Minimum value is 0.
=item Maximum value is G_MAXINT16.
=item Default value is 0.


=comment -----------------------------------------------------------------------
=comment #TP:0:margin-end:
=head2 margin-end

Margin on end of widget, horizontally.

This property supports left-to-right and right-to-left text
directions.

This property adds margin outside of the widget's normal size
request, the margin will be added in addition to the size from
C<.set-size-request()> for example.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_INT
=item Parameter is readable and writable.
=item Minimum value is 0.
=item Maximum value is G_MAXINT16.
=item Default value is 0.


=comment -----------------------------------------------------------------------
=comment #TP:0:margin-start:
=head2 margin-start

Margin on start of widget, horizontally.

This property supports left-to-right and right-to-left text
directions.

This property adds margin outside of the widget's normal size
request, the margin will be added in addition to the size from
C<.set-size-request()> for example.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_INT
=item Parameter is readable and writable.
=item Minimum value is 0.
=item Maximum value is G_MAXINT16.
=item Default value is 0.


=comment -----------------------------------------------------------------------
=comment #TP:0:margin-top:
=head2 margin-top

Margin on top side of widget.

This property adds margin outside of the widget's normal size
request, the margin will be added in addition to the size from
C<.set-size-request()> for example.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_INT
=item Parameter is readable and writable.
=item Minimum value is 0.
=item Maximum value is G_MAXINT16.
=item Default value is 0.


=comment -----------------------------------------------------------------------
=comment #TP:0:name:
=head2 name

The name of the widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_STRING
=item Parameter is readable and writable.
=item Default value is undefined.


=comment -----------------------------------------------------------------------
=comment #TP:0:opacity:
=head2 opacity

The requested opacity of the widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_DOUBLE
=item Parameter is readable and writable.
=item Minimum value is 0.0.
=item Maximum value is 1.0.
=item Default value is 1.0.


=comment -----------------------------------------------------------------------
=comment #TP:0:overflow:
=head2 overflow

How content outside the widget's content area is treated.

This property is meant to be set by widget implementations,
typically in their instance init function.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_ENUM
=item The type of this G_TYPE_ENUM object is GTK_TYPE_OVERFLOW
=item Parameter is readable and writable.
=item Default value is GTK_OVERFLOW_VISIBLE.


=comment -----------------------------------------------------------------------
=comment #TP:0:parent:
=head2 parent

The parent widget of this widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_OBJECT
=item The type of this G_TYPE_OBJECT object is GTK_TYPE_WIDGET
=item Parameter is readable.


=comment -----------------------------------------------------------------------
=comment #TP:0:receives-default:
=head2 receives-default

Whether the widget will receive the default action when it is focused.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:root:
=head2 root

The `GtkRoot` widget of the widget tree containing this widget.

This will be %NULL if the widget is not contained in a root widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_OBJECT
=item The type of this G_TYPE_OBJECT object is GTK_TYPE_ROOT
=item Parameter is readable.


=comment -----------------------------------------------------------------------
=comment #TP:0:scale-factor:
=head2 scale-factor

The scale factor of the widget.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_INT
=item Parameter is readable.
=item Minimum value is 1.
=item Maximum value is G_MAXINT.
=item Default value is 1.


=comment -----------------------------------------------------------------------
=comment #TP:0:sensitive:
=head2 sensitive

Whether the widget responds to input.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is TRUE.


=comment -----------------------------------------------------------------------
=comment #TP:0:tooltip-markup:
=head2 tooltip-markup

Sets the text of tooltip to be the given string, which is marked up
with Pango markup.

Also see C<Gnome::Gtk4::Tooltip.set-markup()>.

This is a convenience property which will take care of getting the
tooltip shown if the given string is not %NULL:
[property@Gtk.Widget:has-tooltip] will automatically be set to %TRUE
and there will be taken care of [signal@Gtk.Widget::query-tooltip] in
the default signal handler.

Note that if both [property@Gtk.Widget:tooltip-text] and
[property@Gtk.Widget:tooltip-markup] are set, the last one wins.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_STRING
=item Parameter is readable and writable.
=item Default value is undefined.


=comment -----------------------------------------------------------------------
=comment #TP:0:tooltip-text:
=head2 tooltip-text

Sets the text of tooltip to be the given string.

Also see C<Gnome::Gtk4::Tooltip.set-text()>.

This is a convenience property which will take care of getting the
tooltip shown if the given string is not %NULL:
[property@Gtk.Widget:has-tooltip] will automatically be set to %TRUE
and there will be taken care of [signal@Gtk.Widget::query-tooltip] in
the default signal handler.

Note that if both [property@Gtk.Widget:tooltip-text] and
[property@Gtk.Widget:tooltip-markup] are set, the last one wins.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_STRING
=item Parameter is readable and writable.
=item Default value is undefined.


=comment -----------------------------------------------------------------------
=comment #TP:0:valign:
=head2 valign

How to distribute vertical space if widget gets extra space.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_ENUM
=item The type of this G_TYPE_ENUM object is GTK_TYPE_ALIGN
=item Parameter is readable and writable.
=item Default value is GTK_ALIGN_FILL.


=comment -----------------------------------------------------------------------
=comment #TP:0:vexpand:
=head2 vexpand
Whether widget wants more vertical space

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:vexpand-set:
=head2 vexpand-set

Whether to use the `vexpand` property.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is FALSE.


=comment -----------------------------------------------------------------------
=comment #TP:0:visible:
=head2 visible

Whether the widget is visible.

=item B<Gnome::GObject::Value> type of this property is G_TYPE_BOOLEAN
=item Parameter is readable and writable.
=item Default value is TRUE.

=end pod
