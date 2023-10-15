module Stippler
using FileIO, ColorTypes

function extract_image_from_file(fileName::String)
	if !isfile(fileName)
		println("""\nThe file \""""*fileName*"""\" does not exist.""")
		println("\nEnter \"exit\" to exit Stippler, or any other string to go back.\n")
		if readline() == "exit"
			exit()
		end
		return nothing
	else
		image = RGB.(load(fileName))
		image = (Float64.(red.(image)) + Float64.(green.(image)) + Float64.(blue.(image))) ./ 3
		image = round.(UInt8, 255 .* image)
		return image::Array{UInt8, 2}
	end
end

function minimumish(image::Array{Float64, 2}, startInd::Tuple{Int, Int})
	
	function find(image::Array{Float64, 2}, ind::Tuple{Int, Int}, margin::Int)
		
		indMin = argmin(image[max(1, ind[1]-margin):min(end, ind[1]+margin), max(1, ind[2]-margin):min(end, ind[2]+margin)])
		indMin = (indMin[1]+max(1, ind[1]-margin)-1, indMin[2]+max(1, ind[2]-margin)-1)
		
		return indMin::Tuple{Int, Int}
		
	end
	
	indMinish = find(image, startInd, 2*HALO_MARGIN)
	if indMinish == startInd
		indMinish = Tuple(argmin(image))
		if indMinish == startInd
			global DONE = true
		end
	end
	
	return indMinish::Tuple{Int, Int}
	
end

function make_dot(image::Array{Float64, 2}, pImage::Array{Float64, 2}, ind::Tuple{Int, Int}, distance::Array{Float64, 2}, io::IOStream)
	
	if COUNT == 2
		global COUNT = 0
		haloRadius = 0.85*(DOT_RADIUS + (HALO_MARGIN/2)*image[ind[1], ind[2]])
		dotRadius = DOT_RADIUS
	else
		global COUNT += 1
		haloRadius = DOT_RADIUS + (HALO_MARGIN/2)*image[ind[1], ind[2]]
		dotRadius = DOT_RADIUS
	end
	
	halo = 4 .* 0.01 .* ((haloRadius ./ distance).^12 .- (haloRadius ./ distance).^6)
	halo[HALO_MARGIN+1, HALO_MARGIN+1] = Inf
	
	pImage[ind[1]-HALO_MARGIN:ind[1]+HALO_MARGIN, ind[2]-HALO_MARGIN:ind[2]+HALO_MARGIN] .+= halo
	println(io, """<circle cx=\"""", ind[2]-HALO_MARGIN, """\" cy=\"""", ind[1]-HALO_MARGIN, """\" r=\"""", dotRadius, """\" />""")
	
	return pImage::Array{Float64, 2}
	
end

function stipple(fileName::String)
	
	fileName = replace(fileName, "\\\\" => "/")
	fileName = replace(fileName, "\\" => "/")
	
	data = extract_image_from_file(fileName)
	if isnothing(data)
		return nothing
	end
	data = Float64.(data) ./ 255
	image = Inf .* ones(size(data) .+ (2*HALO_MARGIN, 2*HALO_MARGIN))
	image[HALO_MARGIN+1:end-HALO_MARGIN, HALO_MARGIN+1:end-HALO_MARGIN] = data
	pImage = deepcopy(image)
	
	c1 = repeat(1:2*HALO_MARGIN+1, 1, 2*HALO_MARGIN+1)
	c2 = c1'
	distance = sqrt.((c1.-(HALO_MARGIN+1)).^2 + (c2.-(HALO_MARGIN+1)).^2)
	
	io = open(stipplerDir*"/output/"*split(split(fileName, "/")[end], ".")[1]*"_stippled.svg", "w")
	
	println(io, """<?xml version="1.0" encoding="UTF-8" standalone="no"?>""")
	println(io, """<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">""")
	println(io, """<svg width=\"""", size(data)[2], """px" height=\"""", size(data)[1], """px" xmlns="http://www.w3.org/2000/svg">""")
	println(io, """<g fill="black">""")
	
	println("\nStippling \"", fileName, "\"...")
	
	indMinish = Tuple(argmin(pImage))
	while !DONE
		if pImage[indMinish[1], indMinish[2]] < 0.95
			pImage = make_dot(image, pImage, indMinish, distance, io)
		end
		indMinish = minimumish(pImage, indMinish)
	end
	
	println(io, """</g>""")
	println(io, """</svg>""")
	
	close(io)
	
	println("...done.")
	
	return nothing
	
end

global DOT_RADIUS = 2.0
global HALO_MARGIN = 20

global COUNT = 0

cd("..")
stipplerDir = replace(pwd(), "\\" => "/")
cd("..")

println("\n------------------------------------------------\n")
println("Welcome to Stippler!")
println("\n------------------------------------------------\n")
println("Stippling is an artistic technique that creates images and shading through the use of tiny identical
dots. The density and arrangement of these dots produce varying levels of light and shadow, adding
depth and dimension. This program automates the stippling process for digital images.

An input image with a size of approximately 2000x2000 pixels in .png format is recommended. The
output is a .svg file with \"_stippled\" added to the file name in the \"output\" folder.")

while(true)
	global DONE = false
	println("\n------------------------------------------------\n")
	println("The current folder is \"", replace(pwd(), "\\" => "/"), "\".\n")
	println("Enter the relative or absolute file path to the input image (for relative paths \".\" indicates the")
	println("current folder and \"..\" the parent folder). Enter any non-file-path string if you want to exit.\n")
	stipple(readline())
end

end # Stippler
