<template>
	<view class="content">
		<view class="line"></view>
		<view class="text">
			一共有{{count}}个应用
		</view>
	</view>
</template>

<script>
	export default {
		props: {
			count: {
				type: Number
			}
		}
	}
</script>

<style scoped>
	.content {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 40rpx;
	}
	
	.text {
		font-size: 28rpx;
		color: #9c9c94;
		text-align: center;
	}
	
	.line {
		height: 1rpx;
		color: #e5e5e5;
	}
</style>