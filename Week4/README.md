# Building an End-to-End Data Pipeline with Azure Storage & Azure Data Factory

## What this project actually was

Honestly, I went into this wanting to stop reading about Azure and actually touch it. So this whole thing was me sitting in the Azure Portal, clicking around, occasionally getting stuck, and eventually getting a file to move from one folder to another using Azure Data Factory (ADF) — which sounds simple when I write it like that, but took a few wrong turns to actually pull off.

The plan: spin up a resource group, create a storage account, drop a CSV into a blob container, wire up an ADF pipeline around it, run it, watch it succeed (or fail, a couple of times), and check the metadata to make sure it actually did what it was supposed to do. A small, contained version of what data engineers do for a living.

For the file itself I grabbed the Superstore dataset off Kaggle — nothing fancy, just a clean CSV that's big enough to feel real but small enough that I wasn't debugging file-size issues on top of everything else.

## Why I did this / what I wanted to get out of it

- Get less intimidated by the Azure Portal in general
- Actually understand how Resource Groups, Storage Accounts, and Containers relate to each other (this took longer than I expected)
- Learn my way around the ADF Studio — Author, Monitor, Manage
- Build a linked service and datasets so ADF could talk to Blob Storage
- Use a Get Metadata activity to check a file before doing anything with it
- Get a Copy Data pipeline running, source to destination
- Understand IAM roles enough to know why "Forbidden" errors happen
- String all of that together into one pipeline that actually runs clean

## What I used

| Service | What it's for |
|---|---|
| Azure Resource Group | The folder everything else lives in |
| Azure Storage Account | Where the blob container lives |
| Blob Container | Where the CSV sits — source and destination |
| Azure Data Factory | The thing that actually connects to storage, copies the file, checks it worked |
| IAM | Decides who (or what) can touch the storage account |

## How it actually went, step by step

### 1. Poking around the Portal and setting up a Resource Group

First time in the Azure Portal, there's just a lot going on. I clicked through a few menus before settling in, then created a Resource Group — basically a labeled folder for every resource I was about to create. Doing this up front saves you from a messy cleanup later, which I've apparently learned the hard way before.

### 2. Storage Account and Blob Container

Inside that resource group, I spun up a Storage Account, then created a Blob Container inside it — think of it as the bucket where the actual files live. I uploaded the Superstore CSV into a source folder in that container. That file became the input for everything that followed.

### 3. Setting up Data Factory and getting lost in the UI for a bit

With storage sorted, I created the Data Factory resource and opened up ADF Studio. This is where most of the actual learning happened. I spent a while just clicking through the three main sections to get a feel for what lives where:

- **Author** — where pipelines, datasets, and data flows get built
- **Monitor** — where you watch runs happen and figure out what broke
- **Manage** — linked services, IAM, the more "behind the scenes" config

### 4. Linked Service and datasets

For ADF to actually reach my storage account, I needed a Linked Service. I authenticated with the storage account key — not the most secure approach long-term, but fine for getting something working.

From there I built two datasets:

- One pointing at the source CSV
- One pointing at an empty destination folder in the same container

### 5. Adding a Get Metadata step

Before letting the pipeline touch anything, I added a Get Metadata activity ahead of the copy. It just reads file properties — name, size, last modified — without moving anything. It felt like overkill at first, but I get why it's standard practice: you want to confirm the file is actually there before you build a whole process around it.

### 6. The Copy Data activity

This was the main piece. I set:

- Source: the Superstore CSV
- Sink: a new path in the destination folder, same container

Got the file format settings right (DelimitedText, correct delimiter, headers on), chained it after the Get Metadata step, and laid out the pipeline so the flow made sense visually too.

### 7. Running it — debug, then trigger, then watching it in Monitor

I ran it in Debug mode first, mostly so I wouldn't publish something broken. Once that came back clean, I triggered it manually to mimic a "real" run. Then I sat in the Monitor tab watching it go — status, duration, clicking into each activity to see what went in and what came out.

### 8. IAM — Reader and Contributor roles

This is where I learned IAM isn't just a checkbox. I went into Access Control on the storage account and assigned:

- **Reader** — can view the setup, can't touch anything
- **Contributor** — can actually read/write, which is what ADF's managed identity needed to do its job

I will say — getting hit with a "Forbidden" error because I'd skipped this step the first time around was annoying in the moment, but it made the concept stick way better than reading about it would have.

### 9. Putting it all together

End to end, the pipeline looks like this:

\`\`\`
Blob Storage (source CSV)
        │
        ▼
Get Metadata Activity  →  confirms the file exists, checks its properties
        │
        ▼
Copy Data Activity  →  copies the CSV to the destination path
        │
        ▼
Blob Storage (destination CSV)
\`\`\`

And it worked — metadata came back correct, the copy completed, and the destination file matched the source.

## What I came away with

A few things that clicked for me by the end of this:

- Resource Groups don't *do* anything on their own — they're purely organizational, but they make life so much easier once you have more than two or three resources running.
- Storage Accounts + Containers are basically Azure's answer to S3 if you've used AWS before.
- The Author / Monitor / Manage split in ADF makes total sense once you've actually used it: build in one place, watch results in another, configure access in a third.
- Get Metadata is a small step that pays off — checking a file exists before you process it is one of those "obvious in hindsight" patterns.
- IAM roles aren't background noise — they decide whether your pipeline can even see the data it's supposed to work with. Hitting a permissions error taught me more than the docs did.
- Watching the run status flip to "Succeeded" in Monitor was a genuinely satisfying moment — first real "okay, this works" feeling of the project.

Overall, a pretty low-stakes way to get hands-on with storage, orchestration, and security in Azure, and actually see how those three pieces depend on each other instead of just reading that they do.

---

##  Resources Used

- Dataset: [Superstore Dataset – Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)
- Assignment Reference Document: Provided via Celebal Technologies LMS (SharePoint)

---

##  Repository Structure (Suggested)

```
Week 4/
├── README.md
├── Resource Group.png
├── source-data container.png
├── ds_source_csv dataset.png
├── ds_destination_csv dataset.png
├── Linked Service.png
├── Linked Service 2.png
├── Get Metadata activity configuration.png
├── Get Metadata activity configuration 2.png
├── pipeline design.png
├── IAM Role assignment.png
├── IAM Role assignment 2.png
├── IAM Role assignment 3.png
└── Mini Project Successful.png
```
