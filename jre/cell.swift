//
//  cell.swift
//  jre
//
//  Created by Edillower Wang on 3/26/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import UIKit

class cell: UITableViewCell {

    @IBOutlet var VideoPreview: UIImageView!

    @IBOutlet var VideoDescription: UILabel!
    
    @IBOutlet var VideoInfo: UILabel!
    
    @IBOutlet var VideoUpVotes: UILabel!
    
    @IBOutlet var VideoDownVotes: UILabel!
    
    @IBOutlet var upVoteButton: UIButton!
    
    @IBOutlet var downVoteButton: UIButton!
}
