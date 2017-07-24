//
//  ViewController.swift
//  ImageCacheDemo
//
//  Created by Anil ORUC on 24/07/2017.
//  Copyright © 2017 Anil ORUC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    let images: [String] = ["https://periscope.com.ua/sites/default/files/1/how-to-photo/landscapes/perspective/land-per08.jpg",
                            "https://www.google.com.tr/search?q=most+viewed+images&sa=X&tbm=isch&imgil=-ISkVl0u2qHaXM%253A%253BgzttUnEff-nhnM%253Bhttp%25253A%25252F%25252Fderestricted.com%25252Fphotography%25252Fpinkbike-most-viewed-100-photos-of-2011-part-2&source=iu&pf=m&fir=-ISkVl0u2qHaXM%253A%252CgzttUnEff-nhnM%252C_&usg=__kADhNkIYwH4ASTbY3Pc1IVUDJzQ%3D&biw=1440&bih=645#imgrc=-ISkVl0u2qHaXM:",
                            "http://derestricted.com/wp-content/uploads/2011/12/drop.jpg",
                            "http://4.bp.blogspot.com/-Xdc1P9906N0/UaJa_3OY-VI/AAAAAAAAJJw/fC2L5d9DCgA/s1600/gNzyESv.jpg",
                            "http://static2.bergfex.com/images/downsized/12/e185569f232e7012_8317a8e7573a6a43.jpg"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let randomIndex = Int(arc4random_uniform(UInt32(images.count)))
        imageView.setImage(urlString: images[randomIndex])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

