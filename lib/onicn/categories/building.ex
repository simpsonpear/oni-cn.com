defmodule Onicn.Categories.Building do
  buildings =
    :onicn
    |> :code.priv_dir()
    |> Path.join("data/buildings.ex")
    |> Code.eval_file()
    |> elem(0)
    |> Macro.escape()

  defmacro __using__(_options) do
    name = __CALLER__.module |> to_string() |> String.split(".") |> List.last()

    quote do
      use Onicn.Content

      def __attributes__ do
        Onicn.Categories.Building.__buildings__()
        |> Enum.find(fn building -> building[:tag] === unquote(name) end)
        |> Enum.into([])
        |> Keyword.put(:name, Macro.underscore(unquote(name)))
      end

      def output(:html_attributes) do
        Onicn.Categories.Building.output(:html_attributes, __MODULE__)
      end

      def output(:link_name_icon) do
        path = "/buildings/#{Macro.underscore(unquote(name))}"
        cn_name = __attributes__()[:cn_name]

        ~s|<a href="#{path}">
          <img src="/img#{path}.png" style="height:16px;"> #{cn_name}
        </a>|
      end

      def output(:edit_link) do
        a = __attributes__()
        "https://github.com/onicn/oni-cn.com/blob/main/lib/onicn/buildings/#{a[:name]}.ex"
      end
    end
  end

  def __building_categories__ do
    [
      base: "基地",
      oxygen: "氧气",
      power: "电力",
      food: "食物",
      plumbing: "液体",
      hvac: "气体",
      refining: "精炼",
      medical: "医疗",
      furniture: "家具",
      utilities: "实用",
      station: "站台",
      automation: "自动化",
      conveyance: "运输",
      rocketry: "火箭"
    ]
  end

  def __buildings__ do
    unquote(buildings)
  end

  def __building_modules__ do
    __buildings__()
    |> Enum.map(fn %{tag: tag} ->
      ["Onicn.Buildings", tag]
      |> Module.concat()
      |> Code.ensure_compiled()
      |> case do
        {:module, module} -> module
        {:error, :nofile} -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def output(:html_body) do
    buildings = Enum.group_by(__buildings__(), &Map.get(&1, :category))

    grouped_buildings =
      Enum.map(__building_categories__(), fn {name, cn_name} ->
        {name, cn_name, buildings[name]}
      end)

    container =
      :onicn
      |> :code.priv_dir()
      |> Path.join("templates/building.eex")
      |> EEx.eval_file(grouped_buildings: grouped_buildings)

    %{
      container: container,
      script: ~s|layui.use('element', function() {});|
    }
  end

  def output(:html_attributes, module) do
    a = module.__attributes__()
    en_name = Macro.underscore(a[:tag])
    img = "/img/buildings/#{en_name}.png"

    data = [
      {"装饰度", "#{a[:base_decor]} (#{a[:base_decor_radius]} 格)"},
      {"占用空间", "宽 #{a[:width_in_cells]} 格，高 #{a[:height_in_cells]} 格"},
      {"建造时间", "#{a[:construction_time]} 秒"},
      {"会被淹没", (a[:floodable] && "是") || "否"},
      {"会被掩埋", (a[:entombable] && "是") || "否"},
      {"会过热", (a[:overheatable] && "是") || "否"}
      | Enum.concat([
          (a[:overheatable] &&
             [
               {"过热温度",
                "#{:erlang.float_to_binary(a[:overheat_temperature] - 273.15, decimals: 2)}°C"}
             ]) || [],
          (is_nil(a[:power_generate]) && []) || [{"电力生产", "#{a[:power_generate]} W"}],
          (is_nil(a[:power_consume]) && []) || [{"电力消耗", "#{a[:power_consume]} W"}],
          (is_nil(a[:heat_generate]) && []) || [{"产热", "#{a[:heat_generate]} kDTU/s"}]
        ])
    ]

    :onicn
    |> :code.priv_dir()
    |> Path.join("templates/attributes.eex")
    |> EEx.eval_file(name: a[:cn_name], img: img, data: data)
  end

  def generate_pages do
    __building_modules__()
    |> Enum.map(&Task.async(fn -> do_generate_page(&1) end))
    |> Enum.each(&Task.await(&1, :infinity))
  end

  defp do_generate_page(module) do
    name = Macro.underscore(module.__attributes__()[:tag])

    temp_path =
      :onicn
      |> :code.priv_dir()
      |> Path.join("templates")

    nav =
      temp_path
      |> Path.join("nav.eex")
      |> EEx.eval_file(nav: "building")

    contents = module.output(:html_content)
    attributes = module.output(:html_attributes)

    container = ~s|
      <div class="layui-row layui-col-space30">
        <div class="layui-col-md8">#{contents}</div>
        <div class="layui-col-md4">#{attributes}</div>
      </div>|

    footer =
      temp_path
      |> Path.join("footer.eex")
      |> EEx.eval_file(edit_link: module.output(:edit_link))

    script = ~s|layui.use('element', function() {});|

    page =
      temp_path
      |> Path.join("index.eex")
      |> EEx.eval_file(nav: nav, container: container, footer: footer, script: script)

    page_path =
      :onicn
      |> :code.priv_dir()
      |> Path.join("dist")
      |> Path.join("/buildings/#{name}/")

    File.mkdir_p!(page_path)
    File.write!(Path.join(page_path, "index.html"), page)
  end
end
