//
//  ValueIterationOperation.m
//  GridWorld
//
//  Created by Troy Chmieleski on 12/8/13.
//  Copyright (c) 2013 Troy Chmieleski. All rights reserved.
//

#import "ValueIterationOperation.h"
#import "Grid.h"
#import "GridCell.h"

@implementation ValueIterationOperation {
	double mDiscountFactor;
	double mIntendedOutcomeProbability;
	double mUnintendedOutcomeProbability;
	Grid mGrid;
}

- (id)initWithGrid:(Grid)grid discountFactor:(double)discountFactor intendedOutcomeProbabilitiy:(double)intendedOutcomeProbability unIntendedOutcomeProbabilitiy:(double)unIntendedOutcomeProbability {
    self = [super init];
	
    if (self) {
		mDiscountFactor = discountFactor;
		mIntendedOutcomeProbability = intendedOutcomeProbability;
		mUnintendedOutcomeProbability = unIntendedOutcomeProbability;
		mGrid = grid;
    }
	
    return self;
}

- (void)main {
	[self valueIteration];
	
	[self didFinish];
}

#pragma mark - Value iteration

/** Determine the grid policy using value iteration
 
 uPrime(s) = reward(s) + discountFactor * max(P(s'|s,a)*uPrime(s'))
 
 */

- (void)valueIteration {
	int numberOfRows = mGrid.numberOfRows();
	int numberOfCols = mGrid.numberOfCols();
	
	int size = numberOfRows*numberOfCols;
	
	vector<double> u(size);
	
	// current utilities
	for (int row = 0; row < numberOfRows; row++) {
		for (int col = 0; col < numberOfCols; col++) {
			int sOffset = row*numberOfCols + col;
			
			u[sOffset] = mGrid.gridCellForRowAndCol(row, col).utility();
		}
	}
	
	// performs 1 iteration
	for (int row = 0; row < numberOfRows; row++) {
		for (int col = 0; col < numberOfCols; col++) {
			// if a wall or terminal state, then skip
			GridCell sCell = mGrid.gridCellForRowAndCol(row, col);
			
			GridCellType sType = sCell.type();
			
			if (sType != GridCellType::GridCellTypeWall && sType != GridCellType::GridCellTypeTerminal) {
				// reward of current state s
				double reward = sCell.reward();
				
				int sOffset = row*numberOfCols + col;
				
				// compute utilities
				double upUtility = [self utilityUsingU:u forToRow:row-1 toCol:col fromRow:row fromCol:col];
				double downUtility = [self utilityUsingU:u forToRow:row+1 toCol:col fromRow:row fromCol:col];
				double leftUtility = [self utilityUsingU:u forToRow:row toCol:col-1 fromRow:row fromCol:col];
				double rightUtility = [self utilityUsingU:u forToRow:row toCol:col+1 fromRow:row fromCol:col];
				
				double maxValue = [self maxValueUsingU:u upUtility:upUtility downUtility:downUtility leftUtility:leftUtility rightUtility:rightUtility intendedOutcomeProbability:mIntendedOutcomeProbability unintendedOutcomeProbability:mUnintendedOutcomeProbability];
				
				u[sOffset] = reward + mDiscountFactor*maxValue;
				
				mGrid.setUtilityForRowAndCol(row, col, u[sOffset]);
			}
		}
	}
}

#pragma mark - Utilities

- (double)utilityUsingU:(vector<double> &)u forToRow:(int)toRow toCol:(int)toCol fromRow:(int)fromRow fromCol:(int)fromCol {
	// figure out the action that maximizes the utility to s'
	int numberOfCols = mGrid.numberOfCols();
	int sOffset = fromRow*numberOfCols + fromCol;
	
	GridCell sPrimeCell = mGrid.gridCellForRowAndCol(toRow, toCol);
	int sPrimeOffset = toRow*numberOfCols + toCol;
	
	// compute utilities
	double utility = u[sPrimeOffset];
	
	// if s' is a wall, then s' = s
	if (sPrimeCell.type() == GridCellType::GridCellTypeWall) {
		utility = u[sOffset];
	}
	
	return utility;
}

#pragma mark - Max Value

- (double)maxValueUsingU:(vector<double> &)u upUtility:(double)upUtility downUtility:(double)downUtility leftUtility:(double)leftUtility rightUtility:(double)rightUtility intendedOutcomeProbability:(double)intendedOutcomeProbability unintendedOutcomeProbability:(double)unintendedOutcomeProbability {
	// maximize the utility
	double maxValue = -DBL_MAX;
	
	// try going up
	double upValue = intendedOutcomeProbability*upUtility + unintendedOutcomeProbability*leftUtility + unintendedOutcomeProbability*rightUtility;
	
	if (upValue > maxValue) {
		maxValue = upValue;
	}
	
	// try going down
	double downValue = intendedOutcomeProbability*downUtility + unintendedOutcomeProbability*leftUtility
	+ unintendedOutcomeProbability*rightUtility;
	
	if (downValue > maxValue) {
		maxValue = downValue;
	}
	
	// try going left
	double leftValue = intendedOutcomeProbability*leftUtility + unintendedOutcomeProbability*upUtility + unintendedOutcomeProbability*rightUtility;
	
	if (leftValue > maxValue) {
		maxValue = leftValue;
	}
	
	// try going right
	double rightValue = intendedOutcomeProbability*rightUtility + unintendedOutcomeProbability*upUtility
	+ unintendedOutcomeProbability*downUtility;
	
	if (rightValue > maxValue) {
		maxValue = rightValue;
	}
	
	return maxValue;
}

- (void)didFinish {
	if (self.valueIterationCompletionBlock) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.valueIterationCompletionBlock(mGrid);
		});
	}
}

@end
