//
//  BlackBox.h
//  ReinforcementLearning
//
//  Created by Troy Chmieleski on 12/9/13.
//  Copyright (c) 2013 Troy Chmieleski. All rights reserved.
//

#ifndef __ReinforcementLearning__BlackBox__
#define __ReinforcementLearning__BlackBox__

#include <iostream>

enum class BlackBoxDirection {
	BlackBoxDirectionUp = 0,
	BlackBoxDirectionDown = 1,
	BlackBoxDirectionLeft = 2,
	BlackBoxDirectionRight = 3
};

class BlackBox {
	double mIntendedProbability;
	double mUintendedProbability;
	
public:
	BlackBox();
	BlackBox(double intendendProbability, double unintendedProability);
	~BlackBox();
	
	BlackBoxDirection actionForIntendedAction(BlackBoxDirection intendedAction);
};

#endif /* defined(__ReinforcementLearning__BlackBox__) */
