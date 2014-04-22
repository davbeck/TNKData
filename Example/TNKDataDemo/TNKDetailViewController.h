//
//  TNKDetailViewController.h
//  TNKDataDemo
//
//  Created by David Beck on 4/22/14.
//  Copyright (c) 2014 ThinkUltimate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TNKDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
