<template>
	<!-- <view class="wrap" v-if="isLoading">
		正在获取{{ app.attribuates.name }}版本信息
	</view> -->
	<view class="content1">
		<view class="titleWrap">
			<text class="title">{{app.attributes.name}}</text>		
		</view>
		
		<view class="wrap" v-if="verInfo">
			<view class="left-item">
				<view class="versionWrap" >
					<text class="version">{{getVersion()}}</text>
					<text style="margin-left: 10rpx;">{{getMinOsVersion()}}</text>
				</view>
				
				<view class="titleWrap">
				<text class="tag">{{verInfo.versionState}}</text>
				</view>
			</view>
			<view class="right-item" v-if="showReleaseBtn">
				<button type="default" style="background-color: #05B2E6; color: white;" @click="requestReleaseApp">发布</button>
				<uni-popup ref="inputDialog" type="dialog">
								<uni-popup-dialog ref="inputClose"  mode="input" title="输入你的姓名" value=""
									placeholder="输入你的姓名" @confirm="dialogInputConfirm"></uni-popup-dialog>
							</uni-popup>
			</view>
		</view>
		
	</view>
	
</template>

<script>
	
	import { toRefs } from "vue";
import config from "../config.js";
	
	export default {
		props: {
			app: {
				type: Object
			}
		},
		data() {
			return {
				verInfo: null,
				showReleaseBtn: false
			}
		},
		
		mounted() {
			// console.log("---" + JSON.stringify(props));
			const appId = this.app.id;
			console.log("+++" + JSON.stringify(appId));
			uni.request({
				url: config.baseUrl() + "appstoreManager/api/appVersion?id="+(appId ?? ""),
				success: (res) => {
					this.verInfo = res.data;
					this.showReleaseBtn = res.data.versionStateRaw != "PENDING_DEVELOPER_RELEASE" || res.data.versionStateRaw == "PENDING_APPLE_RELEASE";
				}
			})
		},
		methods: {
			getMinOsVersion() {
				return ` 兼容iOS${this.verInfo.build.minOsVersion}及以上系统`;
			},
			getVersion: function() {
				return `版本: ${this.verInfo.version}(${this.verInfo.build.version})`
			},
			
			requestReleaseApp: function() {
					this.$refs.inputDialog.open("center")
			},
				
			dialogInputConfirm: function(name) {
				console.log("ddd" + name);
			}
		}
		
	}
</script>

<style scoped>
	
	.content1 {
		display: flex;
		flex-direction: column;
		justify-content: flex-start;
		/* align-items: flex-start; */
		padding-left: 10%;
		padding-right: 10%;
		padding-top: 30rpx;
		padding-bottom: 30rpx;
		border-bottom: 1rpx solid #e5e5e5;
	}
	
	.line {
		/* margin-left: 16rpx; */
		/* margin-right: 16rpx; */
		background-color: #e5e5e5;
		width: 100%;
		height: 2rpx;
	}
	
	.wrap {
		display: flex;
		flex-direction: row;
		width: 100%;
		height: 100%;
		/* padding-left: 10%;
		padding-right: 10%;
		padding-top: 30rpx;
		padding-bottom: 30rpx;
		border-bottom: 1rpx solid #e5e5e5; */

	}
	
	.left-item {
		width: 100%;
		/* height: 200rpx; */
		display: flex;
		flex-direction: column;
		/* align-items: center; */
		justify-content: space-evenly
		
	}
	
	.right-item {
		display: flex;
		flex-direction: column;
		justify-content: center;
		width: 180rpx;
	}
	
	.title {
		font-size: 1.25em;
		font-weight: 800;
	}
	
	.titleWrap {
		padding-bottom: 10rpx;
		padding-top: 10rpx;
		/* display: inline-block; */
		/* flex-direction: column; */
	}
	
	.tag {
		border-radius: 20rpx;
		border-width: 2rpx;
		border-color: #05B2E6;
		border-style: solid;
		padding: 2rpx 8rpx 2rpx 8rpx;
		color: #05B2E6;
		display: inline-block;
		font-weight: 800;
		font-size: 10pt;
	}
	
	.version {
		color: red;
	}
	
	.versionWrap {
		display: flex;
		flex-direction: row;
	}
</style>