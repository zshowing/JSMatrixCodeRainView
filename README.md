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
3. That's all. Just use it as any `UIView`s.

# License

This code is distributed under the terms and conditions of the [MIT license](./LICENSE.md).
