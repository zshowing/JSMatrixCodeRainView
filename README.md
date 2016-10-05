# JSMatrixCodeRainView

**Code Rain**, or [Digital Rain](https://en.wikipedia.org/wiki/Matrix_digital_rain), is a famous visual effect from the Matrix movie trilogy. This view is a Swift implementation to it.

![](http://ww3.sinaimg.cn/large/5613ec79jw1f8hmevmxy9g20a00hsb29.gif)

# Requirements

JSMatrixCodeRainView works on iOS8.0+(Tested) with ARC projects.

It uses the following frameworks:
- Foundation.framework
- UIKit.framework
- QuartzCore.framework

# Usage

1. Modify your Info.plist;

    The view used a customized font called 'Matrix Code NFI', to include that you need to add an entry, `Fonts provided by application` in the `Info.plist`.

    ![](http://ww4.sinaimg.cn/large/5613ec79jw1f8hm06k2djj212m0meth1.jpg)

2. Copy `JSMatrixCodeRainView.swift` and the font file to your project;
3. Configure if needed. There are three configurable variables now:
    - `speed`, a `CGFloat` value, `the unit is in `second`, controls the speed of the animation. The value is the time interval of the characters coming from above.
        For example, the default value is 0.15, which means in every 0.15s, a new character will drop (if reasonable).
    - `newTrackComingLap`, also a `CGFloat` value, the unit is `second`, generally control the number of the tracks.
        Again as an example, the default value is 0.4, means that in every 0.4s, a new track will drop down from the available space (that is, there's no others occupying.)
    - `tracksSpacing`, an `Int` value, the unit is `character`, control the spacing of two tracks.
        The default value is 5, therefore after a track is completely shown, there will be no other track from the same line unless 5 characters passed.
    You can manually set it or set it via Interface Builder, as shown below:

    ![](http://ww1.sinaimg.cn/large/5613ec79jw1f8hq5majxfj20du050jrx.jpg)

4. That's all. Use it as any `UIView`s.

# License

This code is distributed under the terms and conditions of the [MIT license](./LICENSE.md).
