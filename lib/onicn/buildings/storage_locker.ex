defmodule Onicn.Buildings.StorageLocker do
  use Onicn.Categories.Building

  section "简介" do
    "储存箱可用于储存固体元素。玩家可以选择需要储存的元素种类。"
    "储存箱的最大储存容量为20吨，玩家可以手动设定储存容量。"
    "储存箱可以选择“仅限打扫”模式。当选择该模式时，只有玩家使用打扫命令清理的元素才会被搬运至储存箱中。"
    "当周围气压小于1800克时，如漂白石、氧石、淤泥等会持续挥发气体。可以增大气压或放在液体（只需要下面那格在液体中）中来防止气体挥发。"
    "当拆卸储存箱或取消储存元素类型时，原有内容物会掉至地上。"
  end

  section "用途" do
    "没有设置仅限清扫的存储箱可以让复制人自动收集想要的固体。"
    "仅限清扫的存储箱可以存储复制人打扫的固体物质。如果没有对应的存储箱或存储箱满，即使下达了清扫命令复制人也不会搬运。"
    "在建造地点附近放存储箱并且把建造材料提前运过去，可以减少复制人搬运材料往返的时间，提高建造的效率。"
  end

  section "小技巧" do
    "复制人会优先把物体往优先级高的存储箱搬运。也会把物体从优先级低的箱子搬到优先级高的箱子。"
    "会降低装饰，不建议在复制人经常呆的地方大量建造。"
  end
end
