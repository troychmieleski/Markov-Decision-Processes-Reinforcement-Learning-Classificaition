//
//  GridViewController.m
//  ReinforcementLearning
//
//  Created by Troy Chmieleski on 12/9/13.
//  Copyright (c) 2013 Troy Chmieleski. All rights reserved.
//

#import "GridViewController.h"
#import "ReinforcementLearningOperation.h"
#import "Grid.h"
#import "GridCell.h"
#import "GridView.h"
#import "GridCellView.h"
#import <vector>

using namespace std;

#define GRID_WORLD_DISCOUNT_FACTOR .99
#define GRID_WORLD_INTENDED_OUTCOME_PROBABILITIY .80
#define GRID_WORLD_UNINTENDED_OUTCOME_PROBABILITIY .10
#define GRID_WORLD_REINFORCEMENT_NAV_ITEM_TITLE @"Reinforcement Learning"
#define GRID_WORLD_CONTINUE_BUTTON_TITLE @"Continue"
#define GRID_WORLD_AGENT_BUTTON_TITLE @"Agent"
#define GRID_WORLD_STEP_BUTTON_TITLE @"Step"
#define GRID_WORLD_RESET_BUTTON_TITLE @"Reset"
#define GRID_WORLD_GRID_FILE_NAME @"Assignment4GridWorld1"

@implementation GridViewController {
	Grid mGrid;
	GridView *_gridView;
	UIBarButtonItem *_agentButton;
	UIBarButtonItem *_stepButton;
	UIBarButtonItem *_continueButton;
	UIBarButtonItem *_resetButton;
	NSOperationQueue *_queue;
}

- (id)init
{
    self = [super init];
	
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
		[_queue setMaxConcurrentOperationCount:1];
    }
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self setUpNav];
	mGrid = [self parseGrid];
	mGrid.sort();
	[self showGrid];
	[self showQValues];
	[self showPolicies];
}

#pragma mark - Navigation setup

- (void)setUpNav {
	[self.navigationItem setTitle:GRID_WORLD_REINFORCEMENT_NAV_ITEM_TITLE];
	[self.navigationItem setRightBarButtonItems:@[self.stepButton, self.continueButton, self.agentButton, self.resetButton]];
}

#pragma mark - Show grid

- (void)showGrid {
	[self.view addSubview:self.gridView];
	[self.gridView addCellViews];
	
	[self.gridView setNeedsLayout];
}

#pragma mark - Show q values
	
- (void)showQValues {
	[_gridView showQValues];
}

- (void)showPolicies {
	[_gridView showPolicies];
}

#pragma mark - Parse grid

- (Grid)parseGrid {
	NSString *filePath = [[NSBundle mainBundle] pathForResource:GRID_WORLD_GRID_FILE_NAME ofType:@"json"];
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	
	NSError *error;
	NSDictionary *gridDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
	
	if (gridDict) {
		NSNumber *numberOfRows = [gridDict objectForKey:@"numberOfRows"];
		NSNumber *numberOfCols = [gridDict objectForKey:@"numberOfCols"];
		
		NSArray *features = [gridDict objectForKey:@"features"];
		
		vector<GridCell> cells;
		
		for (NSDictionary *feature in features) {
			NSString *type = [feature objectForKey:@"type"];
			
			NSString *wall = @"Wall";
			NSString *nonTerminal = @"Nonterminal";
			NSString *start = @"Start";
			NSString *terminal = @"Terminal";
			
			vector<GridCell> newCells;
			
			GridCellType gridCellType;
			
			id coordinates = [feature objectForKey:@"coordinates"];
			id coordinatesAndRewards = [feature objectForKey:@"coordinatesAndRewards"];
			
			id newCoordinates;
			
			if ([type isEqualToString:wall]) {
				gridCellType = GridCellType::GridCellTypeWall;
				newCoordinates = coordinates;
			}
			
			else if ([type isEqualToString:nonTerminal]) {
				gridCellType = GridCellType::GridCellTypeNonterminal;
				newCoordinates = coordinatesAndRewards;
			}
			
			else if ([type isEqualToString:start]) {
				gridCellType = GridCellType::GridCellTypeStart;
				newCoordinates = coordinatesAndRewards;
			}
			
			else if ([type isEqualToString:terminal]) {
				gridCellType = GridCellType::GridCellTypeTerminal;
				newCoordinates = coordinatesAndRewards;
			}
			
			for (id newCoordinate in newCoordinates) {
				NSUInteger index = 0;
				
				Coordinate point;
				double reward = 0;
				
				for (id value in newCoordinate) {
					double newValue = ((NSNumber *)value).doubleValue;
					
					if (index == 0) {
						point.x = newValue;
					}
					
					else if (index == 1) {
						point.y = newValue;
					}
					
					else if (index == 2) {
						reward = newValue;
					}
					
					index++;
				}
				
				GridCell newCell(gridCellType, point, reward);
				newCells.push_back(newCell);
			}
			
			for (auto it : newCells) {
				cells.push_back(it);
			}
		}
		
		return Grid(numberOfRows.intValue, numberOfCols.intValue, cells);
	}
	
	else {
		UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:nil];
		[av show];
		
		return Grid();
	}
}

#pragma mark - Continue button

- (UIBarButtonItem *)continueButton {
	if (!_continueButton) {
		_continueButton = [[UIBarButtonItem alloc] initWithTitle:GRID_WORLD_CONTINUE_BUTTON_TITLE
														   style:UIBarButtonItemStylePlain
														  target:self
														  action:@selector(continueButtonTouched)];
	}
	
	return _continueButton;
}

#pragma mark - Continue button touched

- (void)continueButtonTouched {
	NSLog(@"continue button touched");
}

#pragma mark - Agent button

- (UIBarButtonItem *)agentButton {
	if (!_agentButton) {
		_agentButton = [[UIBarButtonItem alloc] initWithTitle:GRID_WORLD_AGENT_BUTTON_TITLE style:UIBarButtonItemStylePlain target:self action:@selector(agentButtonTouched)];
	}
	
	return _agentButton;
}

#pragma mark - Agent button touched

- (void)agentButtonTouched {
	NSLog(@"agent button touched");
}

#pragma mark - Step button

- (UIBarButtonItem *)stepButton {
	if (!_stepButton) {
		_stepButton = [[UIBarButtonItem alloc] initWithTitle:GRID_WORLD_STEP_BUTTON_TITLE style:UIBarButtonItemStylePlain target:self action:@selector(stepButtonTouched)];
	}
	
	return _stepButton;
}

#pragma mark - Step button touched

- (void)stepButtonTouched {
	NSLog(@"step button touched");
	
	[self reinforcementLearning];
}

#pragma mark - Reset button

- (UIBarButtonItem *)resetButton {
	if (!_resetButton) {
		_resetButton = [[UIBarButtonItem alloc] initWithTitle:GRID_WORLD_RESET_BUTTON_TITLE style:UIBarButtonItemStylePlain target:self action:@selector(resetButtonTouched)];
	}
	
	return _resetButton;
}

#pragma mark - Reset button touched

- (void)resetButtonTouched {
	NSLog(@"reset button touched");
	
	// reset all q values (this will directly affect the utility values)
	
	[self showQValues];
	[self showPolicies];
}

#pragma mark - Reinforcement learning

- (void)reinforcementLearning {
	
}

#pragma mark - Grid view

- (GridView *)gridView {
	if (!_gridView) {
		_gridView = [[GridView alloc] initWithFrame:CGRectZero];
		[_gridView setDelegate:self];
	}
	
	return _gridView;
}

#pragma mark - Grid view delegate

- (CGFloat)screenWidth {
	return [UIScreen mainScreen].bounds.size.width;
}

- (CGFloat)screenHeight {
	return [UIScreen mainScreen].bounds.size.height;
}

- (NSUInteger)numberOfGridRows {
	return mGrid.numberOfRows();
}

- (NSUInteger)numberOfGridCols {
	return mGrid.numberOfCols();
}

- (GridCellViewType)gridCellViewTypeForRow:(int)row col:(int)col {
	GridCell cell = mGrid.gridCellForRowAndCol(row, col);
	
	GridCellViewType gridCellViewType = GridCellViewTypeWall;
	
	if (cell.type() == GridCellType::GridCellTypeWall) {
		gridCellViewType = GridCellViewTypeWall;
	}
	
	else if (cell.type() == GridCellType::GridCellTypeNonterminal) {
		gridCellViewType = GridCellViewTypeNonterminal;
	}
	
	else if (cell.type() == GridCellType::GridCellTypeStart) {
		gridCellViewType = GridCellViewTypeStart;
	}
	
	else if (cell.type() == GridCellType::GridCellTypeTerminal) {
		gridCellViewType = GridCellViewTypeTerminal;
	}
	
	return gridCellViewType;
}

- (double)rewardForRow:(int)row col:(int)col {
	GridCell cell = mGrid.gridCellForRowAndCol(row, col);
	
	return cell.reward();
}

- (double)qValueForDirection:(Direction)direction atRow:(int)row col:(int)col {
	GridCell cell = mGrid.gridCellForRowAndCol(row, col);
	
	double qValue = 0;
	
	if (direction == DirectionUp) {
		qValue = cell.qValueForGridCellDirection(GridCellDirection::GridCellDirectionUp);
	}
	
	else if (direction == DirectionDown) {
		qValue = cell.qValueForGridCellDirection(GridCellDirection::GridCellDirectionDown);
	}
	
	else if (direction == DirectionLeft) {
		qValue = cell.qValueForGridCellDirection(GridCellDirection::GridCellDirectionLeft);
	}
	
	else if (direction == DirectionRight) {
		qValue = cell.qValueForGridCellDirection(GridCellDirection::GridCellDirectionRight);
	}
	
	return qValue;
}

- (int)numberOfQValues {
	GridCell cell = mGrid.gridCellForRowAndCol(0, 0);
	
	int numberOfQValues = cell.numberOfQValues();
	
	return numberOfQValues;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
