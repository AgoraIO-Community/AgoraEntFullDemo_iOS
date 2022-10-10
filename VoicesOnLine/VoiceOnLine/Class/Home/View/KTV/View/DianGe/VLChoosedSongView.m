//
//  VLChoosedSongView.m
//  VoiceOnLine
//

#import "VLChoosedSongView.h"
#import "VLChoosedSongTCell.h"
#import "VLRoomSelSongModel.h"

@interface VLChoosedSongView ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic, weak) id <VLChoosedSongViewDelegate>delegate;
@property (nonatomic, strong) NSArray *selSongsArray;

@property (nonatomic, strong) UITableView  *tableView;
@property (nonatomic, copy) NSString *roomNo;

@end

@implementation VLChoosedSongView

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id<VLChoosedSongViewDelegate>)delegate {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColorMakeWithHex(@"#152164");
        self.delegate = delegate;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, self.height)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = UIColorMakeWithHex(@"#152164");
    [self addSubview:self.tableView];
    
}

#pragma mark -- UITableViewDataSource UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.selSongsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VL(weakSelf);
    static NSString *reuseCell = @"reuse";
    VLChoosedSongTCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseCell];
    if (cell == nil) {
        cell = [[VLChoosedSongTCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseCell];
    }
    cell.selSongModel = self.selSongsArray[indexPath.row];
    cell.numberLabel.text = [NSString stringWithFormat:@"%d",(int)(indexPath.row+1)];
    cell.sortBtnClickBlock = ^(VLRoomSelSongModel * _Nonnull model) {
        if (model.status == 2) {
            return;
        }
        if (VLUserCenter.user.ifMaster) {
            [weakSelf sortSongEvent:model];
        }
    };
    cell.deleteBtnClickBlock = ^(VLRoomSelSongModel * _Nonnull model) {
        if (model.status == 2) {
            return;
        }
        if (VLUserCenter.user.ifMaster) {
            [weakSelf deleteSongEvent:model];
        }
        
    };
    
    if(VLUserCenter.user.ifMaster) {
        if(indexPath.row == 0 || indexPath.row == 1) {
            cell.sortBtn.hidden = YES;
        }
        else {
            cell.sortBtn.hidden = NO;
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 76;
}


- (void)sortSongEvent:(VLRoomSelSongModel *)model {
    NSDictionary *param = @{
        @"roomNo" : self.roomNo,
        @"songNo": model.songNo,
        @"sort": model.sort
    };
    [VLAPIRequest getRequestURL:kURLRoomMakeSongTop parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
//            [self loadChoosedSongWithRoomNo:self.roomNo];
            [[NSNotificationCenter defaultCenter]postNotificationName:kMakeTopNotification object:nil];
        }
    } failure:^(NSError * _Nullable error, NSURLSessionDataTask * _Nullable task) {
        
    }];
}

- (void)loadChoosedSongWithRoomNo:(NSString *)roomNo {
    self.roomNo = roomNo;
    NSDictionary *param = @{
        @"roomNo" : roomNo
    };

    [VLAPIRequest getRequestURL:kURLChoosedSongs parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            self.selSongsArray = [VLRoomSelSongModel vj_modelArrayWithJson:response.data];
            [self.tableView reloadData];
            [[NSNotificationCenter defaultCenter]postNotificationName:kUpdateSelSongArrayNotification object:self.selSongsArray];
        }
    } failure:^(NSError * _Nullable error, NSURLSessionDataTask * _Nullable task) {

    }];
}

- (NSArray *)getSelSongArray {
    return self.selSongsArray;
}

- (void)deleteSongEvent:(VLRoomSelSongModel *)model {
    NSDictionary *param = @{
        @"roomNo" : self.roomNo,
        @"songNo": model.songNo,
        @"sort":model.sort
    };
    
    [VLAPIRequest getRequestURL:kURLDeleteSong parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
//            [self loadChoosedSongWithRoomNo:self.roomNo];
            [[NSNotificationCenter defaultCenter]postNotificationName:kDeleteSuccessNotification object:nil];
        }
    } failure:^(NSError * _Nullable error, NSURLSessionDataTask * _Nullable task) {
        
    }];
}

- (void)setSelSongsUIWithArray:(NSArray *)selSongsArray {
    _selSongsArray = selSongsArray;
    [self.tableView reloadData];
}

@end
