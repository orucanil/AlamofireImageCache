# AlamofireImageCache

Using AlamofireImage and ANWCacheManager, you can cache images while downloading images.


Installation
--------------

To use the AlamofireImageCache in an app, install AlamofireImage and just drag the AlamofireImageCache files in Classes folder (demo files and assets are not needed) into your project.


Properties
--------------

The AlamofireImageCache has the following properties (note: for iOS, UIImageView when using properties):

    var isImageLoading: Bool

Image loading flag.


Methods
--------------

The AlamofireImageCache has the following methods (note: for iOS, UIImageView in method arguments):

    func setImage(urlString: String?, closure: LoadImageClosure? = nil)

Image loading method with url string and complition block. (Use AlamofireImage for image loading. When finished loading, cached image.)


How to use ?
----------

```Swift


imageView.setImage(urlString: "http://static2.bergfex.com/images/downsized/12/e185569f232e7012_8317a8e7573a6a43.jpg")


```

Build and run the project files. Enjoy more examples!
