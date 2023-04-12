<template>
	<view class="content base">
		<view v-if="isLoading">
		</view>
		<view class="base" v-else-if="list.length">
			<view v-for="(item,index) in list" :key="index">
				<list-item :app="item"></list-item>
			</view>
			<footer :count="list.length"></footer>
		</view>
		<empty-view v-else></empty-view>
	</view>
</template>

<script>
import emptyView from "../../components/empty-view.vue";
import listItem from "../../components/list-item.vue";
import footer from "../../components/footer.vue";
import config from "../../config.js";

	export default {
		components: {emptyView, listItem, footer},
		data() {
			return {
				title: '',
				isLoading: true,
				list: []
			}
		},
		onLoad() {
			uni.showLoading({
				title: "获取应用列表..."
			})
			
			uni.request({
				url: config.baseUrl() + "appstoreManager/api/appList",
				success: (res) => {
					uni.hideLoading()
				  this.title = res.data.count;
					this.list = res?.data?.apps ?? [];
					this.isLoading = false
				}
			})
			
		},
		methods: {

		}
	}
</script>

<style scoped>
	.base {
		width: 100%;
		height: 100%;
	}
	.content {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
	}

</style>
