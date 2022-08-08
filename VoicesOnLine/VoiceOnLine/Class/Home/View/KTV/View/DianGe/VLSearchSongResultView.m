//
//  VLSearchSongResultView.m
//  VoiceOnLine
//

#import "VLSearchSongResultView.h"
#import "VLSelectSongTCell.h"
#import "VLSongItmModel.h"

@interface VLSearchSongResultView()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic, weak) id <VLSearchSongResultViewDelegate>delegate;
@property (nonatomic, strong) UITableView  *tableView;
@property (nonatomic, strong) NSMutableArray *songsMuArray;
@property (nonatomic, assign) NSInteger        page;
@property (nonatomic, copy) NSString *keyWord;
@property (nonatomic, copy) NSString *roomNo;
@property (nonatomic, assign) BOOL ifChorus;

@end

@implementation VLSearchSongResultView

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id<VLSearchSongResultViewDelegate>)delegate withRoomNo:(nonnull NSString *)roomNo ifChorus:(BOOL)ifChorus{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColorMakeWithHex(@"#152164");
        self.ifChorus = ifChorus;
        self.roomNo = roomNo;
        self.delegate = delegate;
        [self setupView];
    }
    return self;
}

- (void)loadSearchDataWithKeyWord:(NSString *)keyWord ifRefresh:(BOOL)ifRefresh {
    self.page = ifRefresh ? 0 : self.page;
    self.keyWord = keyWord;
    NSDictionary *param = @{
        @"name":keyWord ? keyWord : @"",
        @"size":@(5),
        @"current":@(self.page)
    };
    
    [VLAPIRequest getRequestURL:kURLGetSongsList parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            [self.tableView.mj_header endRefreshing];
            self.page += 1;
            NSArray *tempArray = response.data[@"records"];
            NSArray *modelsArray = [VLSongItmModel vj_modelArrayWithJson:tempArray];
            if (ifRefresh) {
                [self.songsMuArray removeAllObjects];
                self.songsMuArray = modelsArray.mutableCopy;
                if (modelsArray.count > 0) {
                    self.tableView.mj_footer.hidden = NO;
                }else{
                    self.tableView.mj_footer.hidden = YES;
                }
            }else{
                for (VLSongItmModel *model in modelsArray) {
                    [self.songsMuArray addObject:model];
                }
            }
            [self.tableView reloadData];
            if (modelsArray.count < 5) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }else{
                [self.tableView.mj_footer endRefreshing];
            }
        }else{
            [self.tableView.mj_header endRefreshing];
        }
        
    } failure:^(NSError * _Nullable error) {
        [self.tableView.mj_header endRefreshing];
    }];

}

- (void)setupView{
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, self.height)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = UIColorMakeWithHex(@"#152164");
    [self addSubview:self.tableView];
    
    VL(weakSelf);
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadSearchDataWithKeyWord:self.keyWord ifRefresh:YES];
    }];
    
    self.tableView.mj_footer = [MJRefreshAutoStateFooter footerWithRefreshingBlock:^{
        [weakSelf loadSearchDataWithKeyWord:self.keyWord ifRefresh:NO];
    }];
}

#pragma mark -- UITableViewDataSource UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.songsMuArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VL(weakSelf);
    static NSString *reuseCell = @"reuse";
    VLSelectSongTCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseCell];
    if (cell == nil) {
        cell = [[VLSelectSongTCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseCell];
    }
    cell.songItemModel = self.songsMuArray[indexPath.row];
    cell.dianGeBtnClickBlock = ^(VLSongItmModel * _Nonnull model) {
        [weakSelf dianGeWithModel:model];
    };
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 78;
}

- (void)dianGeWithModel:(VLSongItmModel*)model {
    NSDictionary *param = @{
        @"isChorus" : @(self.ifChorus),
        @"roomNo": self.roomNo,
        @"songName":model.songName,
        @"songNo":model.songNo,
        @"songUrl":model.songUrl,
        @"userNo":VLUserCenter.user.userNo
    };
    [VLAPIRequest getRequestURL:kURLChooseSong parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            //点歌完成发送通知
            [self dianGeSuccessWithModel:model];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:kDianGeSuccessNotification object:model];
        }
    } failure:^(NSError * _Nullable error) {
        
    }];
}

- (void)dianGeSuccessWithModel:(VLSongItmModel *)songItemModel {
    for (VLSongItmModel *model in self.songsMuArray) {
        if (songItemModel.songNo == model.songNo) {
            model.ifChoosed = YES;
        }
    }
    [self.tableView reloadData];
}

- (NSMutableArray *)songsMuArray {
    if (!_songsMuArray) {
        _songsMuArray = [NSMutableArray array];
    }
    return _songsMuArray;
}

@end
