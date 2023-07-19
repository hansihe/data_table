# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Example.Repo.insert!(%Example.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

lorem = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut sem nulla pharetra diam sit. Lacus laoreet non curabitur gravida arcu. Dolor sit amet consectetur adipiscing elit duis tristique sollicitudin. Augue interdum velit euismod in pellentesque massa placerat duis. Odio ut sem nulla pharetra. Senectus et netus et malesuada fames ac turpis egestas. A arcu cursus vitae congue mauris rhoncus aenean vel elit. Id leo in vitae turpis massa. Ut tristique et egestas quis ipsum suspendisse ultrices. Nibh tortor id aliquet lectus proin nibh nisl condimentum. Senectus et netus et malesuada.

Sed egestas egestas fringilla phasellus faucibus scelerisque eleifend. Vulputate sapien nec sagittis aliquam malesuada. Lacinia quis vel eros donec ac odio tempor orci. Vestibulum lectus mauris ultrices eros in cursus turpis. Id diam maecenas ultricies mi eget. Et netus et malesuada fames ac turpis. Euismod quis viverra nibh cras pulvinar mattis nunc sed. Ornare aenean euismod elementum nisi quis eleifend quam. Fermentum et sollicitudin ac orci phasellus. Sagittis id consectetur purus ut faucibus pulvinar elementum integer. Sit amet facilisis magna etiam tempor. Viverra suspendisse potenti nullam ac tortor. Facilisi etiam dignissim diam quis enim. Pharetra massa massa ultricies mi quis hendrerit. Amet luctus venenatis lectus magna fringilla. Est lorem ipsum dolor sit amet. Euismod nisi porta lorem mollis aliquam ut porttitor. Enim facilisis gravida neque convallis a cras semper auctor neque.

Scelerisque eleifend donec pretium vulputate. At auctor urna nunc id. Libero nunc consequat interdum varius sit amet mattis vulputate. Aliquet bibendum enim facilisis gravida neque convallis a cras. Tempus urna et pharetra pharetra massa massa ultricies mi quis. Egestas quis ipsum suspendisse ultrices gravida. Semper viverra nam libero justo laoreet sit amet cursus. Varius sit amet mattis vulputate enim nulla aliquet. Sed risus pretium quam vulputate dignissim suspendisse in est. Imperdiet nulla malesuada pellentesque elit. Mauris pellentesque pulvinar pellentesque habitant morbi tristique. Non pulvinar neque laoreet suspendisse interdum. Feugiat sed lectus vestibulum mattis ullamcorper velit sed ullamcorper. Vivamus at augue eget arcu dictum varius duis at.

Sit amet justo donec enim diam vulputate ut pharetra. Tempus iaculis urna id volutpat lacus laoreet. Vitae turpis massa sed elementum. At in tellus integer feugiat scelerisque varius. Aliquam eleifend mi in nulla posuere sollicitudin aliquam ultrices. Praesent tristique magna sit amet. Sit amet est placerat in. Adipiscing enim eu turpis egestas pretium. Sed blandit libero volutpat sed cras ornare arcu. Massa ultricies mi quis hendrerit dolor magna. Consectetur purus ut faucibus pulvinar elementum integer enim neque volutpat. Cum sociis natoque penatibus et magnis dis. Amet nisl suscipit adipiscing bibendum est ultricies integer quis.

Nisi quis eleifend quam adipiscing vitae proin sagittis. Nunc scelerisque viverra mauris in aliquam sem. Massa id neque aliquam vestibulum morbi blandit cursus risus. Nisl pretium fusce id velit. Tincidunt augue interdum velit euismod in pellentesque. Facilisi cras fermentum odio eu feugiat. Elementum nisi quis eleifend quam adipiscing. Lectus nulla at volutpat diam ut venenatis. Luctus venenatis lectus magna fringilla. Etiam tempor orci eu lobortis elementum nibh tellus. Massa tincidunt nunc pulvinar sapien et ligula ullamcorper malesuada proin. Ornare massa eget egestas purus. Egestas fringilla phasellus faucibus scelerisque eleifend donec pretium vulputate. Ipsum faucibus vitae aliquet nec ullamcorper sit amet. Congue eu consequat ac felis donec et. Ultrices sagittis orci a scelerisque purus semper eget duis at. Consectetur adipiscing elit duis tristique sollicitudin nibh sit amet commodo. Nullam non nisi est sit amet facilisis magna etiam tempor. Vel pharetra vel turpis nunc eget lorem dolor sed. Eget arcu dictum varius duis at consectetur lorem.
"""
|> String.trim()

for num <- 1..100 do
  Example.Repo.insert!(%Example.Model.Article{
    title: "Example article #{num}",
    body: lorem,
  })
end
